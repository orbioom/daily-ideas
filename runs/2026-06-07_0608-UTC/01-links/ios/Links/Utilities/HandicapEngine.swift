import Foundation

/// World Handicap System math, implemented from the published formulas.
///
/// - Score Differential = (113 / Slope) × (Adjusted Gross − Course Rating)
/// - Handicap Index = average of the best N of the most recent 20 differentials,
///   where N (and a soft adjustment) follow the WHS short-record table.
/// - Course Handicap = round( Index × Slope/113 + (Rating − Par) )
/// - Adjusted Gross caps every hole at Net Double Bogey (par + 2 + strokes
///   received); before a player has an Index, the cap is par + 5.
///
/// Rounds are processed chronologically so each round's Net-Double-Bogey cap
/// uses the Course Handicap implied by the Index established *before* it.
enum HandicapEngine {

    struct RoundResult: Identifiable {
        let id: UUID
        let date: Date
        let adjustedGross: Int
        let gross: Int
        let differential: Double
        let courseHandicapAtPlay: Int
        /// True if this differential is among the best-N currently counted.
        var isCounting: Bool = false
    }

    struct Summary {
        var index: Double?
        var lowIndex: Double?            // lowest index over the trailing window
        var results: [RoundResult] = []  // chronological
        var differentialsUsed: Int = 0
        var totalCounted: Int = 0
    }

    // MARK: - Core formulas

    static func scoreDifferential(adjustedGross: Int, rating: Double, slope: Int) -> Double {
        guard slope > 0 else { return 0 }
        return (113.0 / Double(slope)) * (Double(adjustedGross) - rating)
    }

    static func courseHandicap(index: Double, slope: Int, rating: Double, par: Int) -> Int {
        let raw = index * Double(slope) / 113.0 + (rating - Double(par))
        return Int(raw.rounded())
    }

    /// Distributes a course handicap across holes by stroke index (1 = hardest).
    static func strokesReceived(courseHandicap: Int, strokeIndex: [Int]) -> [Int] {
        let n = strokeIndex.count
        guard n > 0 else { return [] }
        let ch = max(0, courseHandicap)
        let base = ch / n
        let extra = ch % n
        return strokeIndex.map { si in
            base + (si >= 1 && si <= extra ? 1 : 0)
        }
    }

    /// Adjusted gross score with each hole capped at Net Double Bogey. When no
    /// index is established, falls back to a flat par + 5 cap per WHS guidance.
    static func adjustedGross(scores: [Int], pars: [Int], strokeIndex: [Int],
                              courseHandicap: Int?) -> Int {
        var total = 0
        let strokes = courseHandicap.map { strokesReceived(courseHandicap: $0, strokeIndex: strokeIndex) }
        for i in scores.indices where scores[i] > 0 {
            let par = i < pars.count ? pars[i] : 4
            let cap: Int
            if let s = strokes, i < s.count {
                cap = par + 2 + s[i]
            } else {
                cap = par + 5
            }
            total += min(scores[i], cap)
        }
        return total
    }

    // MARK: - WHS short-record table

    /// Returns (numberOfDifferentialsToAverage, adjustment) for a given count.
    static func bestNAndAdjustment(forCount n: Int) -> (Int, Double)? {
        switch n {
        case 0...2: return nil
        case 3:     return (1, -2.0)
        case 4:     return (1, -1.0)
        case 5:     return (1, 0.0)
        case 6:     return (2, -1.0)
        case 7, 8:  return (2, 0.0)
        case 9...11:  return (3, 0.0)
        case 12...14: return (4, 0.0)
        case 15, 16:  return (5, 0.0)
        case 17, 18:  return (6, 0.0)
        case 19:      return (7, 0.0)
        default:      return (8, 0.0)   // 20+
        }
    }

    /// Computes a Handicap Index from a list of recent differentials (most
    /// recent first). Uses only up to the most recent 20.
    static func index(fromRecentDifferentials diffs: [Double]) -> Double? {
        let recent = Array(diffs.prefix(20))
        guard let (n, adj) = bestNAndAdjustment(forCount: recent.count) else { return nil }
        let best = recent.sorted().prefix(n)
        guard !best.isEmpty else { return nil }
        let avg = best.reduce(0, +) / Double(best.count)
        let idx = (avg + adj)
        // WHS caps the index at 54.0; floor at -10 (plus handicaps).
        return min(54.0, max(-10.0, (idx * 10).rounded() / 10))
    }

    // MARK: - Full sequential processing

    /// Processes all rounds, building each round's adjusted gross and
    /// differential using the index established before it, then the final index.
    static func summarize(rounds: [Round]) -> Summary {
        let eligible = rounds
            .filter { $0.countsForHandicap }
            .sorted { $0.date < $1.date }   // chronological

        var results: [RoundResult] = []
        var diffsChrono: [Double] = []

        for r in eligible {
            // Index from differentials known *before* this round (most recent first).
            let priorIndex = index(fromRecentDifferentials: Array(diffsChrono.reversed()))
            let ch: Int? = priorIndex.map {
                courseHandicap(index: $0, slope: r.slopeRating, rating: r.courseRating, par: r.par)
            }
            let adj = adjustedGross(scores: r.holeScores, pars: r.holePars,
                                    strokeIndex: r.holeStrokeIndex, courseHandicap: ch)
            let diff = scoreDifferential(adjustedGross: adj, rating: r.courseRating, slope: r.slopeRating)
            let rounded = (diff * 10).rounded() / 10
            diffsChrono.append(rounded)
            results.append(RoundResult(id: r.id, date: r.date, adjustedGross: adj,
                                       gross: r.totalScore, differential: rounded,
                                       courseHandicapAtPlay: ch ?? 0))
        }

        var summary = Summary()
        summary.results = results
        let recentFirst = Array(diffsChrono.reversed())
        summary.index = index(fromRecentDifferentials: recentFirst)

        // Mark counting differentials in the most recent 20.
        if let (n, _) = bestNAndAdjustment(forCount: min(20, recentFirst.count)) {
            summary.differentialsUsed = n
            summary.totalCounted = min(20, recentFirst.count)
            let recent = Array(recentFirst.prefix(20))
            let threshold = recent.sorted().prefix(n).last
            if let threshold {
                var marked = 0
                // Mark from lowest up to n (handle ties by count).
                let order = results.suffix(20).sorted { $0.differential < $1.differential }
                var countingIDs = Set<UUID>()
                for rr in order where marked < n {
                    if rr.differential <= threshold {
                        countingIDs.insert(rr.id); marked += 1
                    }
                }
                summary.results = results.map { rr in
                    var copy = rr
                    copy.isCounting = countingIDs.contains(rr.id)
                    return copy
                }
            }
        }

        // Low Index: lowest index achievable over the trailing record.
        if recentFirst.count >= 3 {
            var lowest: Double? = nil
            for window in 3...recentFirst.count {
                if let idx = index(fromRecentDifferentials: Array(recentFirst.prefix(window))) {
                    lowest = min(lowest ?? idx, idx)
                }
            }
            summary.lowIndex = lowest
        }
        return summary
    }

    // MARK: - Stableford

    /// Net Stableford points for a hole. netScore = gross − strokes received.
    static func stablefordPoints(gross: Int, par: Int, strokesReceived: Int) -> Int {
        guard gross > 0 else { return 0 }
        let net = gross - strokesReceived
        let delta = net - par   // negative = under par
        switch delta {
        case ..<(-3): return 6   // better than albatross
        case -3: return 5        // albatross
        case -2: return 4        // eagle
        case -1: return 3        // birdie
        case 0:  return 2        // par
        case 1:  return 1        // bogey
        default: return 0
        }
    }

    /// Name for a score relative to par (gross).
    static func scoreName(gross: Int, par: Int) -> String {
        guard gross > 0 else { return "—" }
        switch gross - par {
        case ..<(-2): return "Albatross"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0:  return "Par"
        case 1:  return "Bogey"
        case 2:  return "Double"
        default: return "+\(gross - par)"
        }
    }
}
