import SwiftUI

/// Circular progress ring for the weekly goal. Reduce-Motion friendly.
struct ProgressRing: View {
    let progress: Double          // 0...1
    let lineWidth: CGFloat
    var tint: Color = Theme.accent
    var centerLabel: String? = nil
    var centerSub: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: progress)
            VStack(spacing: 2) {
                if let centerLabel {
                    Text(centerLabel)
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(Theme.ink)
                }
                if let centerSub {
                    Text(centerSub)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly goal progress")
        .accessibilityValue(Format.percent(progress))
    }
}
