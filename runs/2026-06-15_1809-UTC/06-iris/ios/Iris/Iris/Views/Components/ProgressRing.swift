import SwiftUI

/// A soft circular progress ring with a calming gradient stroke.
/// Animation of the trim respects Reduce Motion (caller controls whether `progress` animates).
struct ProgressRing: View {
    /// 0...1 progress.
    var progress: Double
    var lineWidth: CGFloat = 14
    var trackColor: Color = Theme.hairline
    var showGlow: Bool = true

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: 0x3FA4D6), Color(hex: 0x2F9C9C), Color(hex: 0x2F86B8)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: showGlow ? Theme.accent.opacity(0.25) : .clear,
                        radius: showGlow ? 8 : 0)
        }
        .accessibilityHidden(true)
    }
}
