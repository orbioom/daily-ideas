import SwiftUI

/// A soft progress ring used for pregnancy progress. Respects Reduce Motion.
struct RingGauge<Center: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 14
    var tint: Color = Color(hex: 0x9A6FB0)
    @ViewBuilder var center: Center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: progress)
            center
        }
        .accessibilityHidden(true)
    }
}
