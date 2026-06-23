import SwiftUI

/// Circular progress ring for the consistency score, with a label in the center.
struct RingGauge: View {
    /// 0...1 progress.
    let progress: Double
    let centerTitle: String
    let centerSubtitle: String
    var tint: Color = Theme.night
    var lineWidth: CGFloat = 12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let clamped = max(0, min(1, progress))
        ZStack {
            Circle()
                .stroke(Theme.backgroundSecondary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.6), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: clamped)
            VStack(spacing: 2) {
                Text(centerTitle)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(centerSubtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(centerSubtitle)
        .accessibilityValue(centerTitle)
    }
}
