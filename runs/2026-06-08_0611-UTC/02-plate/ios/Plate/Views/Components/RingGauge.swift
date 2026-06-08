import SwiftUI

/// Circular ring showing consumed / target with remaining displayed in the center.
struct RingGauge: View {
    let consumed: Double
    let target: Double
    var ringWidth: CGFloat = 16
    var diameter: CGFloat = 160

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    private var remaining: Double { target - consumed }
    private var isOver: Bool { consumed > target }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Brand.hairline, lineWidth: ringWidth)

            // Fill
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isOver ? Brand.danger : Brand.magic,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(), value: progress)

            // Center labels
            VStack(spacing: 2) {
                Text(Format.kcalShort(abs(remaining)))
                    .font(Brand.mono(28, weight: .semibold))
                    .foregroundStyle(isOver ? Brand.danger : Brand.text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(isOver ? "over" : "left")
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(Format.kcal(abs(remaining)) + (isOver ? " over target" : " remaining"))
    }

    private var accessibilityDescription: String {
        let pct = Int((progress * 100).rounded())
        return "\(pct) percent of daily calorie goal consumed"
    }
}
