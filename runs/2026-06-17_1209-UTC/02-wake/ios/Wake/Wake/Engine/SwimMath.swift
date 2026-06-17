import Foundation

/// Pure swimming calculations. Every division and index is guarded.
enum SwimMath {

    /// Pace per 100 (in the same length unit as `distanceMeters`): seconds / (distance / 100).
    /// Returns nil when distance is non-positive.
    static func pacePer100(seconds: Double, distanceMeters: Double) -> Double? {
        guard distanceMeters > 0, seconds > 0, seconds.isFinite else { return nil }
        let hundreds = distanceMeters / 100.0
        guard hundreds > 0 else { return nil }
        return seconds / hundreds
    }

    /// Seconds per single length of the pool.
    static func secondsPerLength(totalSeconds: Double, distanceMeters: Double, poolLengthMeters: Double) -> Double? {
        guard poolLengthMeters > 0, distanceMeters > 0, totalSeconds > 0 else { return nil }
        let lengths = distanceMeters / poolLengthMeters
        guard lengths > 0 else { return nil }
        return totalSeconds / lengths
    }

    /// SWOLF per length = seconds-per-length + strokes-per-length. Needs a stroke count.
    static func swolf(totalSeconds: Double,
                      distanceMeters: Double,
                      poolLengthMeters: Double,
                      strokesPerLength: Int?) -> Double? {
        guard let strokes = strokesPerLength, strokes > 0 else { return nil }
        guard let spl = secondsPerLength(totalSeconds: totalSeconds,
                                         distanceMeters: distanceMeters,
                                         poolLengthMeters: poolLengthMeters) else { return nil }
        return spl + Double(strokes)
    }

    /// Estimated calories: MET × weightKg × hours, MET from stroke × effort.
    static func calories(stroke: Stroke,
                         effort: Effort,
                         durationSeconds: Double,
                         weightKg: Double) -> Double {
        guard durationSeconds > 0, weightKg > 0 else { return 0 }
        let met = stroke.baseMET * effort.metMultiplier
        let hours = durationSeconds / 3600.0
        return met * weightKg * hours
    }

    /// Total session calories across completed sets, using a moderate effort baseline.
    static func sessionCalories(sets: [CompletedSet], weightKg: Double) -> Double {
        guard weightKg > 0 else { return 0 }
        return sets.reduce(0) { running, set in
            running + calories(stroke: set.stroke,
                               effort: .moderate,
                               durationSeconds: set.actualTimeSeconds,
                               weightKg: weightKg)
        }
    }
}
