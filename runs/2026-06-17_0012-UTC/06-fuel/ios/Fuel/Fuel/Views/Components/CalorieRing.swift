import SwiftUI

/// A big calorie-target ring. The arc shows progress of macro kcal accounted for
/// (always full when macros sum to the target) and the center shows the number.
struct CalorieRing: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let calories: Double
    /// Fraction 0…1 to fill the ring (e.g. macro coverage of the target).
    let fraction: Double
    var subtitle: String = "kcal / day"
    var diameter: CGFloat = 200

    private var clampedFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(FuelTheme.track(scheme), lineWidth: 18)

            Circle()
                .trim(from: 0, to: clampedFraction)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [FuelTheme.orange, FuelTheme.orangeDeep, FuelTheme.orange]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clampedFraction)

            VStack(spacing: 2) {
                Text(Fmt.kcal(calories))
                    .font(FuelTheme.numeral(min(diameter * 0.26, 52)))
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
            }
            .padding(.horizontal, 20)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily calorie target")
        .accessibilityValue("\(Fmt.kcal(calories)) kilocalories")
    }
}
