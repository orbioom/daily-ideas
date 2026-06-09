import SwiftUI

/// A compact circular progress ring used on project rows and detail.
struct ProgressRing: View {
    let fraction: Double          // 0…1
    var size: CGFloat = 34
    var lineWidth: CGFloat = 4
    var tint: Color = Brand.magic

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if clamped >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
