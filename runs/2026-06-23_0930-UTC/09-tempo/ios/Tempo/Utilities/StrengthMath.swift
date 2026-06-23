import Foundation

/// Pure functions for strength estimation. All inputs guarded against bad data.
enum StrengthMath {
    /// Epley estimated 1RM: weight × (1 + reps/30). Returns nil for warm-ups,
    /// non-positive weight, or non-positive reps. For a single rep, returns the weight.
    static func epley(weightKg: Double, reps: Int, warmup: Bool = false) -> Double? {
        guard !warmup, weightKg > 0, reps > 0 else { return nil }
        if reps == 1 { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }

    /// Inverse Epley: target weight for a desired rep count given an e1RM.
    static func weight(forReps reps: Int, oneRepMax: Double) -> Double? {
        guard reps > 0, oneRepMax > 0 else { return nil }
        if reps == 1 { return oneRepMax }
        return oneRepMax / (1.0 + Double(reps) / 30.0)
    }
}

/// Result of a personal-record check for a freshly logged set.
struct PRResult: Equatable {
    var isOneRepMaxPR: Bool
    var isWeightPR: Bool
    var isVolumePR: Bool

    var isAnyPR: Bool { isOneRepMaxPR || isWeightPR || isVolumePR }

    var headline: String {
        if isOneRepMaxPR { return "New estimated 1RM PR" }
        if isWeightPR { return "New top-weight PR" }
        if isVolumePR { return "New set-volume PR" }
        return ""
    }
}

/// Detects whether a candidate set beats the prior best across an exercise's history.
enum PRDetector {
    /// `priorSets` should EXCLUDE the candidate set. Warm-ups are ignored.
    static func evaluate(candidate: SetEntry, against priorSets: [SetEntry]) -> PRResult {
        guard !candidate.isWarmup, candidate.weightKg > 0, candidate.reps > 0 else {
            return PRResult(isOneRepMaxPR: false, isWeightPR: false, isVolumePR: false)
        }
        let working = priorSets.filter { !$0.isWarmup && $0.weightKg > 0 && $0.reps > 0 }

        let priorBest1RM = working.compactMap { $0.estimatedOneRepMax }.max() ?? 0
        let priorMaxWeight = working.map { $0.weightKg }.max() ?? 0
        let priorMaxVolume = working.map { $0.volume }.max() ?? 0

        let candidate1RM = candidate.estimatedOneRepMax ?? 0
        // Small epsilon so re-logging the identical best does not re-trigger.
        let eps = 0.001
        return PRResult(
            isOneRepMaxPR: candidate1RM > priorBest1RM + eps,
            isWeightPR: candidate.weightKg > priorMaxWeight + eps,
            isVolumePR: candidate.volume > priorMaxVolume + eps
        )
    }
}
