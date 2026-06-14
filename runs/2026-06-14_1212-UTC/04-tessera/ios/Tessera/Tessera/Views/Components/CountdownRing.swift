import SwiftUI

/// A circular countdown ring for TOTP. Shows the fraction of the current window
/// remaining and turns amber as it nears expiry. Center can hold a label.
struct CountdownRing: View {
    /// 0 → just rolled (full ring), 1 → about to roll (empty ring).
    let progress: Double
    /// Seconds remaining, shown in the center.
    let secondsRemaining: Int
    var lineWidth: CGFloat = 3.5
    var size: CGFloat = 34

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remainingFraction: Double {
        min(max(1 - progress, 0), 1)
    }

    private var isExpiring: Bool {
        secondsRemaining <= 5
    }

    private var ringColor: Color {
        isExpiring ? Theme.warn : Theme.accent
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: remainingFraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.25), value: remainingFraction)
            Text("\(secondsRemaining)")
                .font(Theme.mono(12, .semibold))
                .foregroundStyle(ringColor)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Code refreshes in \(secondsRemaining) seconds")
    }
}
