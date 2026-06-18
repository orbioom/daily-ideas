import SwiftUI

/// A countdown ring showing progress + remaining time. Pure drawing; the value is
/// supplied by a parent `TimelineView`, so it stays smooth and relaunch-safe.
struct TimerRing: View {
    let progress: Double          // 0...1 elapsed
    let remainingSeconds: Int
    let isFinished: Bool
    var diameter: CGFloat = 120

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: 10)
            Circle()
                .trim(from: 0, to: isFinished ? 1 : clamped)
                .stroke(
                    isFinished ? AnyShapeStyle(Theme.good) : AnyShapeStyle(Theme.heroGradient),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                if isFinished {
                    Image(systemName: "checkmark")
                        .font(.system(size: diameter * 0.28, weight: .bold))
                        .foregroundStyle(Theme.good)
                        .accessibilityHidden(true)
                    Text("Done")
                        .font(Theme.rounded(diameter * 0.13, .bold))
                        .foregroundStyle(Theme.good)
                } else {
                    Text(Fmt.clock(seconds: remainingSeconds))
                        .font(Theme.rounded(diameter * 0.24, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("left")
                        .font(Theme.rounded(diameter * 0.1, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(diameter * 0.18)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFinished ? "Timer finished" : "Time remaining")
        .accessibilityValue(isFinished ? "Done" : Fmt.clock(seconds: remainingSeconds))
    }
}
