import SwiftUI

/// End-of-session summary: score, time, and items to review.
struct DrillSummaryView: View {
    let correct: Int
    let total: Int
    let elapsed: Int
    let reviewItems: [String]
    let onDone: () -> Void

    private var accuracy: Double {
        total > 0 ? Double(correct) / Double(total) : 0
    }

    private var timeString: String {
        let m = elapsed / 60
        let s = elapsed % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private var headline: String {
        switch accuracy {
        case 0.9...: return "Outstanding"
        case 0.7..<0.9: return "Well done"
        case 0.5..<0.7: return "Good effort"
        default: return "Keep going"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: accuracy >= 0.7 ? "star.circle.fill" : "arrow.clockwise.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(accuracy >= 0.7 ? Theme.gold : Theme.accent)
                        .accessibilityHidden(true)
                    Text(headline)
                        .font(Theme.serif(28, .bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 30)

                HStack(spacing: 12) {
                    statTile("\(correct)/\(total)", "Correct", "checkmark")
                    statTile("\(Int((accuracy * 100).rounded()))%", "Accuracy", "percent")
                    statTile(timeString, "Time", "clock")
                }

                if reviewItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Theme.good)
                            .accessibilityHidden(true)
                        Text("Perfect run — nothing to review!")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(22)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("To review", systemImage: "list.bullet.clipboard")
                            .font(Theme.serif(18, .semibold))
                            .foregroundStyle(Theme.ink)
                        ForEach(Array(reviewItems.enumerated()), id: \.offset) { _, item in
                            Text(item)
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.inkSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
                }

                PrimaryButton(title: "Done", systemImage: "checkmark") {
                    onDone()
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func statTile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(20, .bold).monospacedDigit())
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
