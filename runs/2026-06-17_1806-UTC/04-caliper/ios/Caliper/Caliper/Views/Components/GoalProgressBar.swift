import SwiftUI

/// A linear goal-progress bar. Progress is computed as how far the current value
/// has moved from a baseline toward the goal, clamped to 0...1.
struct GoalProgressBar: View {
    let title: String
    let progress: Double      // 0...1
    let detail: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(Int((clamped * 100).rounded()))%")
                    .font(Theme.rounded(14, .bold))
                    .foregroundStyle(Theme.accentDeep)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule()
                        .fill(Theme.heroGradient)
                        .frame(width: max(6, geo.size.width * clamped))
                        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: clamped)
                }
            }
            .frame(height: 10)
            Text(detail)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) goal")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent. \(detail)")
    }
}
