import SwiftUI

/// Circular readiness/progress ring with a centered percentage.
struct ReadinessRing: View {
    let percent: Int          // 0–100
    var size: CGFloat = 150
    var lineWidth: CGFloat = 14
    var caption: String = "Ready"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double { Double(max(0, min(100, percent))) / 100 }

    private var color: Color {
        if percent >= 80 { return Theme.good }
        if percent >= 50 { return Theme.warn }
        return Theme.bad
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: fraction)
            VStack(spacing: 0) {
                Text("\(percent)%")
                    .font(Theme.rounded(size * 0.26, .bold))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text(caption)
                    .font(Theme.rounded(size * 0.09, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) score")
        .accessibilityValue("\(percent) percent")
    }
}

/// Horizontal mastery / progress bar.
struct MasteryBar: View {
    let fraction: Double   // 0–1
    var tint: Color = Theme.accent
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
