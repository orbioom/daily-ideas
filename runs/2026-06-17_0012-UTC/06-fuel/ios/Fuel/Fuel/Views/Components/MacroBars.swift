import SwiftUI

/// One macro row: a colored bar with grams + percentage.
struct MacroBar: View {
    @Environment(\.colorScheme) private var scheme

    let name: String
    let grams: Double
    let percent: Double
    let color: Color
    /// 0…1 fill width relative to the largest macro (for visual scale).
    let fillFraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                Spacer()
                Text(Fmt.grams(grams))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                Text(Fmt.percentWhole(percent))
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
                    .frame(width: 40, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FuelTheme.track(scheme))
                    Capsule()
                        .fill(color)
                        .frame(width: max(6, geo.size.width * min(max(fillFraction, 0), 1)))
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue("\(Int(grams.rounded())) grams, \(Int(percent.rounded())) percent of calories")
    }
}

/// The three macro bars laid out together, scaled to the largest gram value.
struct MacroBarsView: View {
    let macros: MacroTargets

    private var maxGrams: Double {
        max(macros.proteinG, macros.carbG, macros.fatG, 1)
    }

    var body: some View {
        VStack(spacing: 14) {
            MacroBar(name: "Protein",
                     grams: macros.proteinG,
                     percent: macros.proteinPercent,
                     color: FuelTheme.protein,
                     fillFraction: macros.proteinG / maxGrams)
            MacroBar(name: "Carbs",
                     grams: macros.carbG,
                     percent: macros.carbPercent,
                     color: FuelTheme.carbs,
                     fillFraction: macros.carbG / maxGrams)
            MacroBar(name: "Fat",
                     grams: macros.fatG,
                     percent: macros.fatPercent,
                     color: FuelTheme.fat,
                     fillFraction: macros.fatG / maxGrams)
        }
    }
}
