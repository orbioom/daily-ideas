import SwiftUI

/// End-of-session summary: score, accuracy, and which words leveled up.
struct ResultsView: View {
    let correct: Int
    let total: Int
    let accuracy: Double
    let leveledUp: [VocabWord]
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var headline: String {
        switch accuracy {
        case 0.9...:    return "Outstanding"
        case 0.7..<0.9: return "Well done"
        case 0.5..<0.7: return "Good effort"
        default:        return "Keep going"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack {
                    Circle().stroke(Theme.hairline, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: appeared ? accuracy : 0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: appeared)
                    VStack(spacing: 2) {
                        Text("\(Int((accuracy * 100).rounded()))%")
                            .font(Theme.rounded(34, .bold))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText())
                        Text("accuracy")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .frame(width: 168, height: 168)
                .padding(.top, 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Accuracy \(Int((accuracy * 100).rounded())) percent")

                Text(headline)
                    .font(Theme.serif(28, .bold))
                    .foregroundStyle(Theme.ink)

                Text("You got \(correct) of \(total) correct.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)

                if leveledUp.isEmpty {
                    LexemeCard {
                        Text("No level-ups this round — but every review strengthens the memory. Keep them coming.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 18)
                } else {
                    LexemeCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Leveled up", systemImage: "arrow.up.circle.fill")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.accent)
                            ForEach(leveledUp) { w in
                                HStack {
                                    Text(w.word)
                                        .font(Theme.serif(17, .medium))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    POSTag(pos: w.partOfSpeech)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }

                PrimaryButton(title: "Done", systemImage: "checkmark") {
                    Haptics.tap()
                    onDone()
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
            }
            .padding(.bottom, 32)
        }
        .background(Theme.bg)
        .onAppear {
            appeared = true
            if accuracy >= 0.7 { Haptics.success() }
        }
    }

    private var ringColor: Color {
        accuracy >= 0.7 ? Theme.good : (accuracy >= 0.5 ? Theme.gold : Theme.bad)
    }
}
