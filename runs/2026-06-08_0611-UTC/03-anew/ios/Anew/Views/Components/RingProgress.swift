import SwiftUI

/// Circular progress ring for milestone next-target display.
struct RingProgress: View {
    let progress: Double   // 0.0…1.0
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4
    var color: Color = Brand.live

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Brand.ease(0.5), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
