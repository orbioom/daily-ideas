import Foundation

/// Pure strength math: 1RM estimation and barbell plate loading.
enum StrengthMath {

    /// Estimated one-rep max in the same unit as `weight`.
    /// Returns `weight` for a single rep; 0 for invalid input.
    static func oneRepMax(weight: Double, reps: Int, formula: OneRepMaxFormula) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        if reps == 1 { return weight }
        switch formula {
        case .epley:
            return weight * (1 + Double(reps) / 30.0)
        case .brzycki:
            // Guard the denominator; Brzycki degrades past ~36 reps.
            let denom = 37.0 - Double(reps)
            guard denom > 0 else { return weight * (1 + Double(reps) / 30.0) }
            return weight * 36.0 / denom
        }
    }

    /// Estimated weight for a target rep count given a known 1RM (inverse Epley).
    static func weightFor(oneRepMax: Double, reps: Int) -> Double {
        guard oneRepMax > 0, reps > 0 else { return 0 }
        if reps == 1 { return oneRepMax }
        return oneRepMax / (1 + Double(reps) / 30.0)
    }

    /// Greedy plate loading for one side of a barbell.
    /// Returns the plates to put on each side and how much weight can't be matched.
    struct PlateResult {
        var perSide: [(plate: Double, count: Int)]
        var achievable: Double   // total bar weight actually loaded
        var leftover: Double     // requested minus achievable (>= 0)
    }

    static func loadPlates(target: Double, bar: Double, plates: [Double]) -> PlateResult {
        guard target > bar, !plates.isEmpty else {
            return PlateResult(perSide: [], achievable: max(bar, min(bar, target)), leftover: max(0, target - bar))
        }
        let perSideTarget = (target - bar) / 2.0
        var remaining = perSideTarget
        var result: [(Double, Int)] = []
        for plate in plates.sorted(by: >) where plate > 0 {
            let count = Int((remaining + 1e-9) / plate)
            if count > 0 {
                result.append((plate, count))
                remaining -= Double(count) * plate
            }
        }
        let loadedPerSide = perSideTarget - remaining
        let achievable = bar + loadedPerSide * 2
        return PlateResult(perSide: result,
                           achievable: achievable,
                           leftover: max(0, target - achievable))
    }
}
