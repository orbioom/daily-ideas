import SwiftUI

/// Circular ring showing actual sleep duration vs goal.
/// The center displays a monospaced duration string.
struct DurationRing: View {
    let durationHours: Double
    let goalHours: Double
    /// If true, text is shown in the center; if false, only the ring.
    var showCenter: Bool = true
    var ringSize: CGFloat = 140

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var progress: Double {
        guard goalHours > 0 else { return 0 }
        return min(durationHours / goalHours, 1.0)
    }

    private var ringColor: Color {
        if durationHours >= goalHours { return Brand.live }
        if durationHours >= goalHours * 0.8 { return Brand.warn }
        return Brand.danger
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Brand.hairline, style: StrokeStyle(lineWidth: 10, lineCap: .round))

            // Progress arc
            Circle()
                .trim(from: 0, to: reduceMotion ? progress : (appeared ? progress : 0))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.7), value: appeared)

            if showCenter {
                VStack(spacing: 1) {
                    Text(Format.duration(durationHours))
                        .font(Brand.mono(22, weight: .semibold))
                        .foregroundStyle(Brand.text)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("of \(Format.duration(goalHours))")
                        .font(Brand.mono(11, weight: .regular))
                        .foregroundStyle(Brand.text3)
                }
                .accessibilityHidden(true)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .onAppear {
            if !reduceMotion { appeared = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep duration")
        .accessibilityValue("\(Format.duration(durationHours)) of goal \(Format.duration(goalHours))")
    }
}
