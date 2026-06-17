import Foundation

/// Estimated one-rep-max formulas. Reps guarded to keep results finite.
enum OneRepMax {
    /// Epley: w · (1 + reps/30). At 1 rep returns the weight itself.
    static func epley(weightKg: Double, reps: Int) -> Double {
        guard weightKg > 0, reps > 0 else { return max(weightKg, 0) }
        let r = Double(min(reps, 36))
        return weightKg * (1 + r / 30.0)
    }

    /// Brzycki: w · 36 / (37 − reps). Undefined at 37 reps; guarded to <37.
    static func brzycki(weightKg: Double, reps: Int) -> Double {
        guard weightKg > 0, reps > 0 else { return max(weightKg, 0) }
        let r = min(reps, 36)
        let denom = 37 - r
        guard denom > 0 else { return weightKg }
        return weightKg * 36.0 / Double(denom)
    }

    /// Average of Epley and Brzycki — a steadier single estimate.
    static func estimate(weightKg: Double, reps: Int) -> Double {
        (epley(weightKg: weightKg, reps: reps) + brzycki(weightKg: weightKg, reps: reps)) / 2.0
    }

    /// Best e1RM across a set of (weight, reps) pairs.
    static func best(from sets: [(weightKg: Double, reps: Int)]) -> Double {
        sets.map { estimate(weightKg: $0.weightKg, reps: $0.reps) }.max() ?? 0
    }
}
