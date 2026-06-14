import SwiftUI

/// A circular 0–10 score badge tinted by sentiment tier.
struct ScoreChip: View {
    let score: Double
    let sentiment: Sentiment?
    var size: CGFloat = 44
    @EnvironmentObject private var settings: AppSettings

    private var tint: Color { sentiment?.color ?? Theme.inkSoft }

    var body: some View {
        Text(settings.formatScore(score))
            .font(Theme.rounded(size * 0.34, .bold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(tint.opacity(0.14))
                    .overlay(Circle().strokeBorder(tint.opacity(0.35), lineWidth: 1.5))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Score")
            .accessibilityValue("\(settings.formatScore(score)) out of 10")
    }
}
