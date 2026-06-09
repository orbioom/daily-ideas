import SwiftUI

/// A circular progress ring with a centered label. Reduce-motion friendly.
struct ProgressRing: View {
    var progress: Double          // 0…1
    var lineWidth: CGFloat = 12
    var tint: Color = Brand.live
    var size: CGFloat = 120
    @ViewBuilder var label: () -> AnyView

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.5), value: progress)
            label()
        }
        .frame(width: size, height: size)
    }
}
