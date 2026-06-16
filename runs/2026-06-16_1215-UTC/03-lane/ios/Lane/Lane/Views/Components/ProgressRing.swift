import SwiftUI

/// A compact circular progress indicator. Honors Reduce Motion (no spring on update).
struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 44
    var lineWidth: CGFloat = 5
    var tint: Color = Theme.accent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: clamped)
            Text("\(Int(clamped * 100))%")
                .font(Theme.rounded(min(size * 0.26, 13), .semibold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}
