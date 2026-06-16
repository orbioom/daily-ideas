import SwiftUI

/// The celebratory end-of-round screen.
struct EndScreen: View {
    let model: GameViewModel
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                Text(headline)
                    .font(.system(size: 64))
                    .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.6))
                    .opacity(appeared ? 1 : 0)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                StarsView(earned: model.starsEarned, size: 40)
                    .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                    .opacity(appeared ? 1 : 0)

                Card {
                    HStack {
                        scoreItem(value: "\(model.correctCount)/\(model.total)", label: "Correct")
                        Divider().frame(height: 40)
                        scoreItem(value: model.accuracyText, label: "Accuracy")
                        Divider().frame(height: 40)
                        scoreItem(value: "\(model.starsEarned)", label: "Stars")
                    }
                }
                .padding(.horizontal, 20)

                gettingGoodAt
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    PrimaryButton(title: "Play again", systemImage: "arrow.clockwise", action: onPlayAgain)
                    PrimaryButton(title: "Done", fill: false, action: onDone)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }

    private var headline: String {
        switch model.starsEarned {
        case 3: return "🌟"
        case 2: return "🎉"
        case 1: return "👍"
        default: return "💪"
        }
    }

    private var title: String {
        switch model.starsEarned {
        case 3: return "Perfect round!"
        case 2: return "Great work!"
        case 1: return "Nice effort!"
        default: return "Keep practicing!"
        }
    }

    private func scoreItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    @ViewBuilder
    private var gettingGoodAt: some View {
        let facts = uniqueImproving
        if !facts.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Facts you're getting good at")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    FlowChips(items: facts.map { $0.prompt })
                }
            }
        }
    }

    private var uniqueImproving: [Question] {
        var seen = Set<String>()
        var result: [Question] = []
        for q in model.improvingFacts where !seen.contains(q.identityKey) {
            seen.insert(q.identityKey)
            result.append(q)
            if result.count >= 8 { break }
        }
        return result
    }
}

/// A simple wrapping row of chips.
struct FlowChips: View {
    let items: [String]
    private let columns = [GridItem(.adaptive(minimum: 78), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.good)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.good.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
    }
}
