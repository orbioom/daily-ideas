import Foundation

/// A scaled ingredient line, ready for display.
struct ScaledLine: Identifiable {
    let id: UUID
    let name: String
    let scaledQuantity: Double
    let unit: MeasureUnit
    /// Optional weight readout in grams when a density is known and the unit is volume.
    let weightGrams: Double?

    /// Formatted quantity using cooking fractions when enabled.
    func quantityText(useFractions: Bool) -> String {
        FractionFormatter.string(scaledQuantity, useFractions: useFractions)
    }

    /// Formatted weight, e.g. "≈ 240 g".
    var weightText: String? {
        guard let weightGrams, weightGrams > 0 else { return nil }
        return "≈ " + FractionFormatter.tidyDecimal(weightGrams) + " g"
    }
}

/// Pure recipe-scaling engine.
enum ScaleEngine {

    /// Compute a scaling factor for a target serving count vs a base count.
    /// Guards against a zero base serving count.
    static func factor(baseServings: Int, targetServings: Int) -> Double {
        guard baseServings > 0 else { return 1 }
        return Double(targetServings) / Double(baseServings)
    }

    /// Scale ingredients by `factor`. When `includeWeights` is true and a matching
    /// density is found for a volume ingredient, also compute a grams readout.
    static func scale(
        ingredients: [RecipeIngredient],
        by factor: Double,
        includeWeights: Bool
    ) -> [ScaledLine] {
        let safeFactor = factor.isFinite ? max(0, factor) : 1
        return ingredients
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { ing in
                let qty = ing.quantity * safeFactor
                var grams: Double? = nil
                if includeWeights, ing.unit.kind == .volume,
                   let ml = ing.unit.millilitersPerUnit,
                   let density = matchedDensity(for: ing.name) {
                    grams = qty * ml * density.gramsPerMl
                }
                return ScaledLine(
                    id: ing.id,
                    name: ing.name,
                    scaledQuantity: qty,
                    unit: ing.unit,
                    weightGrams: grams
                )
            }
    }

    /// Best-effort match of an ingredient name to a library density.
    static func matchedDensity(for name: String) -> IngredientDensity? {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lowered.isEmpty else { return nil }
        // Exact id match first.
        if let exact = IngredientLibrary.ingredient(id: lowered) { return exact }
        // Then a contains match (e.g. "sifted all-purpose flour").
        return IngredientLibrary.all.first { lowered.contains($0.id) }
            ?? IngredientLibrary.all.first { $0.id.contains(lowered) && lowered.count > 3 }
    }
}
