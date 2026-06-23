import SwiftUI

/// A circular progress ring with a centered percentage label.
struct ProgressRing: View {
    let progress: Double          // 0...1
    var lineWidth: CGFloat = 10
    var size: CGFloat = 84
    var tint: Color = Theme.primary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(1, max(0, progress)) }
    private var percent: Int { Int((clamped * 100).rounded()) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: clamped)
            Text("\(percent)%")
                .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Packing progress")
        .accessibilityValue("\(percent) percent packed")
    }
}
