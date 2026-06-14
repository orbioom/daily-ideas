import SwiftUI

/// Big countdown ring for a timed step: shows remaining time with a draining arc.
struct CountdownRing: View {
    /// 0...1 fraction elapsed (ring drains as this grows).
    let progress: Double
    /// Whole seconds remaining, for the centered label.
    let remaining: Int
    let icon: String
    var size: CGFloat = 240

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.accentSoft, lineWidth: 14)
            Circle()
                .trim(from: 0, to: 1 - clamped)
                .stroke(
                    Theme.accent,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: size * 0.16, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(TimeFormat.clock(remaining))
                    .font(Theme.rounded(size * 0.2, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time remaining")
        .accessibilityValue(TimeFormat.spoken(remaining))
    }
}
