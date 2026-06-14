import SwiftUI

/// A calm circular progress ring used on the detail screen.
struct ProgressRing: View {
    /// 0...1
    var progress: Double
    var lineWidth: CGFloat = 14
    var track: Color
    var fill: AnyShapeStyle
    var reduceMotion: Bool = false

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
        }
        .accessibilityHidden(true)
    }
}
