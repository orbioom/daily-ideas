import SwiftUI

/// A circular progress ring with a centered streak count. Used on Today + Progress.
struct StreakRing: View {
    let streak: Int
    /// 0...1 progress (e.g. fraction of a weekly goal) for the ring fill.
    let progress: Double
    var size: CGFloat = 96
    var caption: String = "day streak"

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.accentSoft, lineWidth: 9)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Theme.accent,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(streak)")
                    .font(Theme.rounded(size * 0.34, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.16))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streak) \(caption)")
    }
}
