import Foundation

/// Pure calculations over workout templates.
enum WorkoutMath {

    /// Total planned distance in meters across all sets.
    static func totalDistance(of sets: [SwimSet]) -> Double {
        sets.reduce(0) { $0 + $1.totalDistanceMeters }
    }

    /// Estimated duration in seconds. Uses send-off when present, otherwise an
    /// effort-scaled swim estimate plus the fixed rest.
    static func estimatedDuration(of sets: [SwimSet]) -> Int {
        var total = 0.0
        for set in sets {
            let reps = Double(max(1, set.repeats))
            if set.sendOffSeconds > 0 {
                // Each rep consumes its full interval.
                total += reps * Double(set.sendOffSeconds)
            } else {
                let swim = reps * estimatedRepSeconds(distanceMeters: set.distancePerRepMeters,
                                                      stroke: set.stroke,
                                                      effort: set.effort)
                let rest = reps * Double(max(0, set.restSeconds))
                total += swim + rest
            }
        }
        return Int(total.rounded())
    }

    /// Rough swim time for one rep, from a per-100 pace baseline by stroke & effort.
    static func estimatedRepSeconds(distanceMeters: Double, stroke: Stroke, effort: Effort) -> Double {
        guard distanceMeters > 0 else { return 0 }
        let basePer100 = basePace(stroke: stroke)
        let factor: Double
        switch effort {
        case .easy: factor = 1.15
        case .moderate: factor = 1.0
        case .hard: factor = 0.9
        case .race: factor = 0.82
        }
        let per100 = basePer100 * factor
        return (distanceMeters / 100.0) * per100
    }

    /// A plausible per-100 seconds baseline for a recreational swimmer.
    private static func basePace(stroke: Stroke) -> Double {
        switch stroke {
        case .freestyle: return 100
        case .backstroke: return 115
        case .breaststroke: return 130
        case .butterfly: return 120
        case .im: return 120
        case .kick: return 150
        case .drill: return 130
        case .choice: return 110
        }
    }
}
