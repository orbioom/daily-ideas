import SwiftUI

/// A circular home-health gauge (0...100).
struct HealthGauge: View {
    let score: Double                       // 0...100
    var size: CGFloat = 168
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(score, 0), 100) }

    private var color: Color {
        switch clamped {
        case 80...: return Theme.good
        case 50..<80: return Theme.warn
        default: return Theme.bad
        }
    }

    private var label: String {
        switch clamped {
        case 90...: return "Excellent"
        case 75..<90: return "Healthy"
        case 50..<75: return "Needs attention"
        default: return "Behind"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, lineWidth: 16)
            Circle()
                .trim(from: 0, to: CGFloat(clamped / 100))
                .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
            VStack(spacing: 2) {
                Text("\(Int(clamped.rounded()))")
                    .font(Theme.rounded(46, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(label)
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Home health score")
        .accessibilityValue("\(Int(clamped.rounded())) out of 100, \(label)")
    }
}
