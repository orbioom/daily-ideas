import Foundation

/// Transparent, self-contained round-rating estimator.
///
/// PDGA round ratings scale linearly with how a round compares to the course's
/// Scratch Scoring Average (SSA): a round equal to SSA rates ~1000, and every
/// throw above SSA costs a roughly fixed number of points (≈10 on a typical
/// course). Official ratings derive SSA and the per-throw value from event
/// propagators; here both are course properties you can tune, so the math is
/// honest and reproducible rather than a black box.
enum RatingEngine {

    /// Estimated round rating from total strokes against a course baseline.
    static func rating(strokes: Int, ssa: Double, pointsPerThrow: Double) -> Int {
        guard strokes > 0, pointsPerThrow > 0 else { return 0 }
        let value = 1000.0 + (ssa - Double(strokes)) * pointsPerThrow
        return Int(value.rounded())
    }

    /// Strokes that would produce a given target rating (inverse of `rating`).
    static func strokesForRating(_ target: Int, ssa: Double, pointsPerThrow: Double) -> Double {
        guard pointsPerThrow > 0 else { return ssa }
        return ssa - (Double(target) - 1000.0) / pointsPerThrow
    }

    /// A rough difficulty-aware default for points-per-throw given hole count.
    /// Shorter layouts spread fewer points per throw; this keeps estimates sane
    /// when a user has not tuned the value.
    static func suggestedPointsPerThrow(holeCount: Int) -> Double {
        guard holeCount > 0 else { return 10 }
        // ~10 points/throw at 18 holes; scale inversely with hole count.
        return (180.0 / Double(holeCount)).rounded(toPlaces: 1)
    }

    /// A descriptive tier for a rating value.
    static func tier(for rating: Int) -> String {
        switch rating {
        case 1000...: return "Pro / Open"
        case 950..<1000: return "Advanced+"
        case 900..<950: return "Advanced"
        case 850..<900: return "Intermediate"
        case 800..<850: return "Recreational"
        case 1..<800: return "Novice"
        default: return "—"
        }
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let m = pow(10.0, Double(places))
        return (self * m).rounded() / m
    }
}
