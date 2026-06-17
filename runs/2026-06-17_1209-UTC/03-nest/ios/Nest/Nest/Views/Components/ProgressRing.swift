import SwiftUI

/// A satisfying circular progress ring with a centered symbol or label.
struct ProgressRing: View {
    let fraction: Double           // 0...1
    let color: Color
    var lineWidth: CGFloat = 12
    var symbolName: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: lineWidth * 1.6, weight: .semibold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            } else {
                Text("\(Int((clamped * 100).rounded()))%")
                    .font(Theme.money(lineWidth * 1.5, .bold))
                    .foregroundStyle(Theme.ink)
                    .accessibilityHidden(true)
            }
        }
    }
}
