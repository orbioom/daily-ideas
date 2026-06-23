import SwiftUI

/// Circular home-health gauge (0...100). Respects Reduce Motion by skipping the
/// sweep animation.
struct HealthGauge: View {
    let score: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { Double(min(100, max(0, score))) / 100.0 }

    private var tint: Color {
        switch score {
        case ..<50: return Theme.overdue
        case 50..<80: return Theme.due
        default: return Theme.ok
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.bgSecondary, lineWidth: 12)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.7), value: clamped)
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text("home health")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 120, height: 120)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Home health score")
        .accessibilityValue("\(score) out of 100")
    }
}
