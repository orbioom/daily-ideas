import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [KanaCard]
    @State private var engine = KanaEngine()
    @State private var selectedType: CardType? = nil
    @State private var isFlipped: Bool = false
    @State private var flipDegrees: Double = 0
    @AppStorage(KanaSettings.showRomaji) private var showRomaji: Bool = false
    @AppStorage(KanaSettings.hapticFeedback) private var hapticFeedback: Bool = true
    @State private var sessionStarted: Bool = false
    @State private var totalInSession: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if !sessionStarted {
                    idleView
                } else if engine.isSessionComplete {
                    completionView
                } else if let card = engine.currentCard {
                    activeStudyView(card: card)
                } else {
                    idleView
                }
            }
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Idle / Start View

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(KanaTheme.crimsonRed)

                Text("Ready to Study?")
                    .font(.title)
                    .fontWeight(.bold)

                let dueCount = engine.cardsDueToday(allCards)
                Text("\(dueCount) card\(dueCount == 1 ? "" : "s") due today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Type picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Type")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TypeFilterChip(label: "All", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(CardType.allCases, id: \.self) { type in
                            TypeFilterChip(
                                label: type.displayName,
                                color: KanaTheme.cardTypeColor(type),
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Button(action: startSession) {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(KanaTheme.crimsonRed)
                    )
            }
            .padding(.horizontal, 32)
            .disabled(engine.cardsDueToday(allCards) == 0 && selectedType != nil)

            Spacer()
        }
    }

    // MARK: - Active Study View

    private func activeStudyView(card: KanaCard) -> some View {
        VStack(spacing: 20) {
            // Progress bar
            VStack(spacing: 8) {
                let remaining = engine.studyQueue.count
                let done = totalInSession - remaining
                let progress = totalInSession > 0 ? Double(done) / Double(totalInSession) : 0

                HStack {
                    Text("\(done) / \(totalInSession)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(engine.sessionCorrect) correct")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(KanaTheme.crimsonRed)
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.spring(), value: progress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal)
            }

            Spacer()

            // Card
            ZStack {
                // Back face
                CardFaceView(
                    card: card,
                    isFront: false,
                    showRomaji: true
                )
                .rotation3DEffect(.degrees(flipDegrees < 90 ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(flipDegrees >= 90 ? 1 : 0)

                // Front face
                CardFaceView(
                    card: card,
                    isFront: true,
                    showRomaji: showRomaji
                )
                .rotation3DEffect(.degrees(flipDegrees >= 90 ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(flipDegrees < 90 ? 1 : 0)
            }
            .onTapGesture {
                if !engine.showAnswer {
                    flipCard()
                }
            }

            // Type badge
            HStack {
                Image(systemName: KanaTheme.cardTypeIcon(card.cardType))
                    .foregroundStyle(KanaTheme.cardTypeColor(card.cardType))
                Text(card.cardType.displayName)
                    .font(.caption)
                    .foregroundStyle(KanaTheme.cardTypeColor(card.cardType))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(KanaTheme.cardTypeColor(card.cardType).opacity(0.12))
            )

            Spacer()

            // Answer buttons or Show Answer
            if engine.showAnswer {
                HStack(spacing: 16) {
                    Button(action: { respondToCard(card: card, correct: false) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("Again")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red)
                        )
                    }

                    Button(action: { respondToCard(card: card, correct: true) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Got It!")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button(action: flipCard) {
                    Text("Show Answer")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(KanaTheme.crimsonRed)
                        )
                }
                .padding(.horizontal, 24)
                .transition(.opacity)
            }

            Spacer().frame(height: 16)
        }
        .animation(.easeInOut(duration: 0.2), value: engine.showAnswer)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }

            Text("Session Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                let total = engine.sessionCorrect + engine.sessionIncorrect
                let acc = total > 0 ? Double(engine.sessionCorrect) / Double(total) : 0

                HStack(spacing: 32) {
                    StatBadge(value: "\(total)", label: "Reviewed")
                    StatBadge(value: "\(engine.sessionCorrect)", label: "Correct", color: .green)
                    StatBadge(value: "\(Int(acc * 100))%", label: "Accuracy", color: acc >= 0.7 ? .green : .orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button(action: startSession) {
                    Label("Study Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(KanaTheme.crimsonRed)
                        )
                }

                Button(action: { sessionStarted = false }) {
                    Text("Done for Now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Actions

    private func startSession() {
        engine.loadQueue(from: allCards, type: selectedType)
        totalInSession = engine.studyQueue.count
        sessionStarted = true
        isFlipped = false
        flipDegrees = 0
        engine.showAnswer = false
    }

    private func flipCard() {
        withAnimation(.easeInOut(duration: 0.4)) {
            flipDegrees = 180
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            engine.showAnswer = true
        }
    }

    private func respondToCard(card: KanaCard, correct: Bool) {
        if hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: correct ? .medium : .rigid)
            generator.impactOccurred()
        }
        engine.answer(correct: correct, card: card, context: modelContext)
        withAnimation(.easeInOut(duration: 0.2)) {
            flipDegrees = 0
        }
    }
}

// MARK: - Card Face View

struct CardFaceView: View {
    let card: KanaCard
    let isFront: Bool
    let showRomaji: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)

            if isFront {
                VStack(spacing: 16) {
                    Text(card.character)
                        .font(.system(size: 96, weight: .regular, design: .default))
                        .minimumScaleFactor(0.5)

                    if showRomaji {
                        Text(card.romaji)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text(card.character)
                        .font(.system(size: 64, weight: .regular, design: .default))

                    Text(card.romaji)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(KanaTheme.crimsonRed)

                    if !card.meaning.isEmpty {
                        Text(card.meaning)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.horizontal, 24)
    }
}

// MARK: - Supporting Views

struct TypeFilterChip: View {
    let label: String
    var color: Color = KanaTheme.crimsonRed
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.12))
                )
        }
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
