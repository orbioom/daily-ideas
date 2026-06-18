import Foundation

/// Pure cooking-math engine. All division is guarded; results have sane floors.
enum CookEngine {

    /// Absolute floor for any computed cook time (minutes). Prevents 0-minute cooks.
    static let minMinutes = 2

    /// Preheat minutes added when the user opts in.
    static let preheatMinutes = 3

    /// Result of a scaled cook computation.
    struct Result: Equatable {
        let tempF: Int
        let minutes: Int
        let shakeOrFlipAtMin: Int?
        let portionMultiplier: Double
        let preheatAdded: Bool
    }

    /// Computes cook temp/time for a food given a requested portion in grams.
    ///
    /// Scaling uses a *sub-linear* curve: doubling the food does not double the time,
    /// because the air fryer's heat capacity dominates. We scale by `ratio^0.6`,
    /// clamp the ratio to a safe band, and never drop below `minMinutes`.
    static func compute(
        food: Food,
        frozen: Bool,
        requestedGrams: Double,
        includePreheat: Bool
    ) -> Result {
        let variant = food.variant(frozen: frozen)

        // Guard the base grams so we never divide by zero or by a negative.
        let baseGrams = max(food.basePortionGrams, 1)
        let safeRequested = max(requestedGrams, 1)

        // Clamp the raw ratio to a reasonable cooking band (0.25x – 4x).
        let rawRatio = safeRequested / baseGrams
        let ratio = min(max(rawRatio, 0.25), 4.0)

        // Sub-linear curve so large batches don't get wildly long times.
        let curved = pow(ratio, 0.6)

        let scaledMinutes = Double(variant.minutes) * curved
        var minutes = Int(scaledMinutes.rounded())
        if includePreheat { minutes += preheatMinutes }
        minutes = max(minutes, minMinutes)

        // Keep the flip reminder proportional, but only if the variant had one.
        let flip: Int?
        if let baseFlip = variant.shakeOrFlipAtMin {
            let scaledFlip = Int((Double(baseFlip) * curved).rounded())
            // Flip should land strictly inside the cook window.
            flip = min(max(scaledFlip, 1), max(minutes - 1, 1))
        } else {
            flip = nil
        }

        return Result(
            tempF: variant.tempF,
            minutes: minutes,
            shakeOrFlipAtMin: flip,
            portionMultiplier: curved,
            preheatAdded: includePreheat
        )
    }
}
