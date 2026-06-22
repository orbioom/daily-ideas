import SwiftUI

struct TimerRing: View {
    let progress: Double  // 1.0 = full, 0.0 = empty
    let timeRemaining: Int
    let isWarning: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ringColor: Color {
        if progress > 0.5 {
            return Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255) // sky blue
        } else if progress > 0.25 {
            return Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255) // orange
        } else {
            return Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255) // coral/red
        }
    }

    private var textColor: Color { ringColor }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    ringColor.opacity(0.2),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 1.0), value: progress)

            // Center text
            VStack(spacing: 2) {
                Text("\(timeRemaining)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(textColor)
                    .contentTransition(.numericText())

                Text("sec")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
            }
            .scaleEffect(isWarning && !reduceMotion ? 1.05 : 1.0)
            .animation(
                isWarning && !reduceMotion
                    ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                    : .default,
                value: isWarning
            )
        }
        .accessibilityLabel("\(timeRemaining) seconds remaining")
        .accessibilityValue(isWarning ? "Warning: time is running low" : "")
    }
}
