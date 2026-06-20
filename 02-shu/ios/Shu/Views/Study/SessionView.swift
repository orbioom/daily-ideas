import SwiftUI
import SwiftData

// MARK: - Study Mode
enum StudyMode: CaseIterable {
    case flashcard
    case toneQuiz
    case meaningQuiz
    case writing

    var title: String {
        switch self {
        case .flashcard:  return "Flashcard"
        case .toneQuiz:   return "Tone Quiz"
        case .meaningQuiz: return "Meaning Quiz"
        case .writing:    return "Writing"
        }
    }
}

// MARK: - SessionView
struct SessionView: View {
    var srsEngine: SRSEngine
    let cards: [CardReview]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var currentMode: StudyMode = .flashcard
    @State private var cardsReviewed = 0
    @State private var correctCount = 0
    @State private var isSessionComplete = false

    private var currentCard: CardReview? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    private var currentWord: HskWord? {
        guard let card = currentCard else { return nil }
        return HskWord.find(id: card.wordId)
    }

    var body: some View {
        ZStack {
            ShuTheme.darkNavy.ignoresSafeArea()

            if isSessionComplete {
                SessionCompleteView(
                    cardsReviewed: cardsReviewed,
                    correctCount: correctCount,
                    onDismiss: { dismiss() }
                )
            } else if let card = currentCard, let word = currentWord {
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader

                    // Study card area
                    studyContent(card: card, word: word)
                }
            } else {
                // Shouldn't happen, but safe fallback
                Text("No cards available")
                    .foregroundStyle(ShuTheme.subtleText)
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ShuTheme.subtleText)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }

                Spacer()

                Text("\(currentMode.title)")
                    .font(ShuTheme.labelFont(size: 14))
                    .foregroundStyle(ShuTheme.subtleText)

                Spacer()

                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(ShuTheme.labelFont(size: 14))
                    .foregroundStyle(ShuTheme.subtleText)
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ShuTheme.gold)
                        .frame(width: geo.size.width * (Double(currentIndex) / Double(max(1, cards.count))))
                        .animation(.spring(response: 0.4), value: currentIndex)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Study Content Router
    @ViewBuilder
    private func studyContent(card: CardReview, word: HskWord) -> some View {
        switch currentMode {
        case .flashcard:
            FlashcardView(word: word, onRate: { rating in
                advance(card: card, rating: rating, correct: rating >= 3)
            })
        case .toneQuiz:
            ToneQuizView(word: word, onResult: { correct in
                advance(card: card, rating: correct ? 4 : 1, correct: correct)
            })
        case .meaningQuiz:
            MeaningQuizView(word: word, onResult: { correct in
                advance(card: card, rating: correct ? 4 : 1, correct: correct)
            })
        case .writing:
            WritingView(word: word, onResult: { correct in
                advance(card: card, rating: correct ? 4 : 1, correct: correct)
            })
        }
    }

    // MARK: - Advance
    private func advance(card: CardReview, rating: Int, correct: Bool) {
        srsEngine.processRating(rating, for: card)
        cardsReviewed += 1
        if correct { correctCount += 1 }

        let nextIndex = currentIndex + 1
        if nextIndex >= cards.count {
            saveSession()
            withAnimation { isSessionComplete = true }
        } else {
            // Pick next mode randomly (weighted)
            currentMode = randomMode()
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex = nextIndex
            }
        }
    }

    private func randomMode() -> StudyMode {
        // Weight: flashcard 30%, toneQuiz 25%, meaningQuiz 30%, writing 15%
        let weights: [(StudyMode, Double)] = [
            (.flashcard,   0.30),
            (.toneQuiz,    0.25),
            (.meaningQuiz, 0.30),
            (.writing,     0.15),
        ]
        let roll = Double.random(in: 0..<1)
        var cumulative = 0.0
        for (mode, weight) in weights {
            cumulative += weight
            if roll < cumulative { return mode }
        }
        return .flashcard
    }

    private func saveSession() {
        let session = StudySession(
            date: .now,
            cardsReviewed: cardsReviewed,
            correctCount: correctCount
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}

// MARK: - Session Complete View
private struct SessionCompleteView: View {
    let cardsReviewed: Int
    let correctCount: Int
    let onDismiss: () -> Void

    private var accuracy: Int {
        guard cardsReviewed > 0 else { return 0 }
        return Int(Double(correctCount) / Double(cardsReviewed) * 100)
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Trophy icon
            ZStack {
                Circle()
                    .fill(ShuTheme.gold.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(ShuTheme.gold)
            }

            VStack(spacing: 12) {
                Text("Session Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ShuTheme.primaryText)

                Text("Great work — your memory is getting stronger.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(ShuTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Stats
            HStack(spacing: 0) {
                completeStat(value: "\(cardsReviewed)", label: "Reviewed")
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 48)
                completeStat(value: "\(correctCount)", label: "Correct")
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 48)
                completeStat(value: "\(accuracy)%", label: "Accuracy")
            }
            .padding(.vertical, 24)
            .background(ShuTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: ShuTheme.cardRadius))
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(ShuTheme.darkNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ShuTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private func completeStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(ShuTheme.gold)
            Text(label)
                .font(ShuTheme.labelFont(size: 12))
                .foregroundStyle(ShuTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SessionView(srsEngine: SRSEngine(), cards: [])
        .modelContainer(for: [CardReview.self, StudySession.self], inMemory: true)
}
