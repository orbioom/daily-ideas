import Foundation

/// Result of a conversion attempt.
enum ConversionResult: Equatable {
    case success(value: Double)
    /// Cross volume↔weight conversion attempted with no ingredient density chosen.
    case needsIngredient
    /// A guard tripped (e.g. zero density). Carries a recoverable message.
    case invalid(reason: String)
}

/// Pure conversion engine. No state, no side effects.
enum ConversionEngine {

    /// Convert `amount` from `from` to `to`.
    /// - `gramsPerCup`: required only for cross volume↔weight conversions; ignored otherwise.
    static func convert(
        amount: Double,
        from: MeasureUnit,
        to: MeasureUnit,
        gramsPerCup: Double? = nil
    ) -> ConversionResult {
        guard amount.isFinite else { return .invalid(reason: "Enter a valid amount.") }

        // Same-kind conversions never need a density.
        if from.kind == to.kind {
            switch from.kind {
            case .volume:
                guard let fromMl = from.millilitersPerUnit,
                      let toMl = to.millilitersPerUnit, toMl != 0 else {
                    return .invalid(reason: "Unable to convert these units.")
                }
                return .success(value: amount * fromMl / toMl)
            case .weight:
                guard let fromG = from.gramsPerUnit,
                      let toG = to.gramsPerUnit, toG != 0 else {
                    return .invalid(reason: "Unable to convert these units.")
                }
                return .success(value: amount * fromG / toG)
            }
        }

        // Cross-type: requires a density.
        guard let gramsPerCup, gramsPerCup > 0 else {
            return .needsIngredient
        }

        // gramsPerMl from gramsPerCup (1 cup = 236.588 ml). Guard divide-by-zero.
        guard let cupMl = MeasureUnit.cup.millilitersPerUnit, cupMl > 0 else {
            return .invalid(reason: "Unable to convert these units.")
        }
        let gramsPerMl = gramsPerCup / cupMl
        guard gramsPerMl > 0 else {
            return .invalid(reason: "This ingredient has no density.")
        }

        if from.kind == .volume && to.kind == .weight {
            guard let fromMl = from.millilitersPerUnit,
                  let toG = to.gramsPerUnit, toG > 0 else {
                return .invalid(reason: "Unable to convert these units.")
            }
            let grams = amount * fromMl * gramsPerMl
            return .success(value: grams / toG)
        } else {
            // weight -> volume
            guard let fromG = from.gramsPerUnit,
                  let toMl = to.millilitersPerUnit, toMl > 0 else {
                return .invalid(reason: "Unable to convert these units.")
            }
            let grams = amount * fromG
            let ml = grams / gramsPerMl
            return .success(value: ml / toMl)
        }
    }

    /// Whether a from→to pair requires an ingredient density.
    static func requiresIngredient(from: MeasureUnit, to: MeasureUnit) -> Bool {
        from.kind != to.kind
    }
}
