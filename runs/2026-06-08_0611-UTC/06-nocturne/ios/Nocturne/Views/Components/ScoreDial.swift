import SwiftUI

/// Arc-style dial showing a 0–100 score (e.g. regularity).
struct ScoreDial: View {
    let score: Int          // 0...100
    let label: String
    var dialSize: CGFloat = 110

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var progress: Double { Double(score) / 100.0 }

    private var dialColor: Color {
        if score >= 75 { return Brand.live }
        if score >= 45 { return Brand.warn }
        return Brand.danger
    }

    // Arc spans 240° starting at 150° (bottom-left)
    private let startAngle: Double = 150
    private let sweepAngle: Double = 240

    var body: some View {
        ZStack {
            // Track arc
            Circle()
                .trim(from: 0, to: sweepAngle / 360)
                .stroke(Brand.hairline, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(startAngle))

            // Filled arc
            let fill = (reduceMotion ? progress : (appeared ? progress : 0)) * sweepAngle / 360
            Circle()
                .trim(from: 0, to: fill)
                .stroke(dialColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(startAngle))
                .animation(reduceMotion ? nil : Brand.ease(0.7), value: appeared)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(Brand.mono(24, weight: .bold))
                    .foregroundStyle(Brand.text)
                Text(label)
                    .font(Brand.mono(10, weight: .medium))
                    .foregroundStyle(Brand.text3)
                    .multilineTextAlignment(.center)
            }
            .accessibilityHidden(true)
        }
        .frame(width: dialSize, height: dialSize)
        .onAppear {
            if !reduceMotion { appeared = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(score) out of 100")
    }
}
