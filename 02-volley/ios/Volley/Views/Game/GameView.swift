import SwiftUI
import SwiftData

struct GameView: View {
    let mode: QuestionMode
    let category: QuestionCategory
    let questions: [Question]
    let questionCount: Int
    let settings: AppSettings?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var engine = VolleyEngine()
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0
    @State private var showCompletion = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var gradientColors: [Color] { VolleyTheme.gradient(for: mode) }

    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showCompletion {
                GameCompletionView(
                    mode: mode,
                    answered: engine.sessionAnswered,
                    skipped: engine.sessionSkipped,
                    gradientColors: gradientColors
                ) {
                    dismiss()
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Exit game")

                        Spacer()

                        // Mode badge
                        HStack(spacing: 6) {
                            Image(systemName: VolleyTheme.icon(for: mode))
                                .font(.caption)
                            Text(mode.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())

                        Spacer()

                        Text(engine.progressDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    // Question card
                    if let question = engine.currentQuestion {
                        QuestionCard(question: question, gradientColors: gradientColors)
                            .padding(.horizontal, 20)
                            .offset(x: cardOffset)
                            .rotationEffect(.degrees(cardRotation))
                            .animation(reduceMotion ? .none : .spring(response: 0.4), value: cardOffset)
                            .id(engine.currentIndex) // Re-renders on index change
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    Spacer()

                    // Progress bar
                    VStack(spacing: 20) {
                        ProgressView(value: engine.progress)
                            .tint(.white)
                            .padding(.horizontal, 20)
                            .accessibilityLabel("Progress: \(Int(engine.progress * 100)) percent")

                        // Action buttons
                        HStack(spacing: 16) {
                            Button(action: handleSkip) {
                                HStack(spacing: 6) {
                                    Image(systemName: "forward.fill")
                                    Text("Skip")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .accessibilityLabel("Skip question")

                            Button(action: handleNext) {
                                HStack(spacing: 6) {
                                    Text("Next")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.headline.bold())
                                .foregroundStyle(gradientColors.first ?? .orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .accessibilityLabel("Next question")
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            engine.loadQuestions(
                questions,
                mode: mode,
                category: category,
                safeMode: settings?.safeMode ?? false,
                limit: questionCount
            )
        }
    }

    private func handleNext() {
        if settings?.hapticsEnabled ?? true {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        animateCard(direction: -1) {
            engine.next()
            if engine.isComplete {
                saveSession()
                withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.4)) {
                    showCompletion = true
                }
            }
        }
    }

    private func handleSkip() {
        if settings?.hapticsEnabled ?? true {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        animateCard(direction: 1) {
            engine.skip()
            if engine.isComplete {
                saveSession()
                withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.4)) {
                    showCompletion = true
                }
            }
        }
    }

    private func animateCard(direction: CGFloat, completion: @escaping () -> Void) {
        if reduceMotion {
            completion()
            return
        }
        withAnimation(.easeIn(duration: 0.2)) {
            cardOffset = direction * 400
            cardRotation = direction * 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cardOffset = direction * -400
            cardRotation = direction * -8
            completion()
            withAnimation(.spring(response: 0.35)) {
                cardOffset = 0
                cardRotation = 0
            }
        }
    }

    private func saveSession() {
        let session = GameSession(
            date: .now,
            mode: mode.rawValue,
            category: category.rawValue,
            questionsAnswered: engine.sessionAnswered,
            questionsSkipped: engine.sessionSkipped
        )
        modelContext.insert(session)
    }
}

struct QuestionCard: View {
    let question: Question
    let gradientColors: [Color]

    var body: some View {
        VStack(spacing: 24) {
            // Category badge
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                Text(question.category.capitalized)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.white.opacity(0.15))
            .clipShape(Capsule())

            // Question text
            Text(question.text)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)

            // Custom badge
            if question.isCustom {
                Label("Custom Question", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.12))
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
    }
}

struct GameCompletionView: View {
    let mode: QuestionMode
    let answered: Int
    let skipped: Int
    let gradientColors: [Color]
    let onDismiss: () -> Void

    private var total: Int { answered + skipped }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("Game Over!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(mode.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 20) {
                CompletionStat(value: "\(answered)", label: "Answered")
                Divider()
                    .frame(height: 40)
                    .background(.white.opacity(0.4))
                CompletionStat(value: "\(skipped)", label: "Skipped")
                Divider()
                    .frame(height: 40)
                    .background(.white.opacity(0.4))
                CompletionStat(value: "\(total)", label: "Total")
            }
            .padding()
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onDismiss) {
                Text("Play Again")
                    .font(.headline.bold())
                    .foregroundStyle(gradientColors.first ?? .orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct CompletionStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
