import Foundation

/// The heart of Inkling: for every (factor, outcome) pair of trackers, compute how strongly the
/// factor's daily value tracks the outcome's — using Pearson's r over the days both were logged.
/// Supports a same-day reading (lag 0) and a next-day reading (lag +1: does the factor *today*
/// predict the symptom *tomorrow*). All math guards n<4 and zero variance so it never divides by
/// zero and never over-claims on thin data.
enum CorrelationEngine {

    enum Strength: String {
        case weak, moderate, strong

        var label: String {
            switch self {
            case .weak: return "Weak"
            case .moderate: return "Moderate"
            case .strong: return "Strong"
            }
        }
    }

    enum Direction {
        case positive   // factor up → outcome up
        case negative   // factor up → outcome down

        var label: String { self == .positive ? "raises" : "lowers" }
        var sign: String { self == .positive ? "+" : "−" }
    }

    /// One ranked correlation finding between a factor and an outcome.
    struct Result: Identifiable {
        let id = UUID()
        let factorID: UUID
        let outcomeID: UUID
        let factorName: String
        let outcomeName: String
        let r: Double            // Pearson coefficient, -1...1
        let n: Int               // number of overlapping days used
        let lag: Int             // 0 or 1

        var strength: Strength {
            let a = abs(r)
            if a >= 0.5 { return .strong }
            if a >= 0.3 { return .moderate }
            return .weak
        }

        var direction: Direction { r >= 0 ? .positive : .negative }

        /// How much we trust this, blending |r| with sample size. 0...1.
        var confidence: Double {
            let sampleFactor = min(1.0, Double(n) / 30.0)
            return min(1.0, abs(r) * 0.6 + sampleFactor * 0.4)
        }

        var confidenceLabel: String {
            if n < 7 { return "Low confidence · only \(n) days" }
            if confidence >= 0.6 { return "Good confidence · \(n) days" }
            return "Fair confidence · \(n) days"
        }

        /// A plain-English reading of the finding.
        func reading(factorScale: String, outcomeScale: String) -> String {
            let dir = direction == .positive ? "higher" : "lower"
            let verb = direction.label
            return "On days with more \(factorName.lowercased()), \(outcomeName.lowercased()) tends to be \(dir)"
                + (lag == 1 ? " the next day." : " the same day.")
                + " The link is \(strength.label.lowercased()) (\(verb) it)."
        }
    }

    /// Minimum overlapping days before we'll report a coefficient at all.
    static let minSamples = 4

    /// Pearson correlation of two equal-length series. Returns nil if too short or either series
    /// has (near) zero variance.
    static func pearson(_ xs: [Double], _ ys: [Double]) -> Double? {
        guard xs.count == ys.count, xs.count >= minSamples else { return nil }
        let n = Double(xs.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var sxy = 0.0, sxx = 0.0, syy = 0.0
        for i in 0..<xs.count {
            let dx = xs[i] - meanX
            let dy = ys[i] - meanY
            sxy += dx * dy
            sxx += dx * dx
            syy += dy * dy
        }
        let denom = (sxx * syy).squareRoot()
        guard denom > 1e-9 else { return nil }    // zero variance → undefined; don't divide
        let r = sxy / denom
        // Clamp tiny floating drift outside [-1, 1].
        return max(-1.0, min(1.0, r))
    }

    /// Build paired (factor, outcome) series for a given lag from two day→value maps. With lag 1
    /// we pair factor on day d with outcome on day d+1.
    static func pairedSeries(factor: [Date: Double],
                             outcome: [Date: Double],
                             lag: Int) -> (xs: [Double], ys: [Double], days: [Date]) {
        var xs: [Double] = [], ys: [Double] = [], days: [Date] = []
        for (day, fv) in factor {
            let outDay: Date
            if lag == 0 {
                outDay = day
            } else {
                guard let shifted = DayMath.calendar.date(byAdding: .day, value: lag, to: day) else { continue }
                outDay = shifted
            }
            if let ov = outcome[outDay] {
                xs.append(fv)
                ys.append(ov)
                days.append(day)
            }
        }
        return (xs, ys, days)
    }

    /// A tracker reduced to a day→value map plus identity, ready for correlation.
    struct Series {
        let id: UUID
        let name: String
        let isOutcome: Bool
        let byDay: [Date: Double]
    }

    /// Rank every factor→outcome pairing for the requested lag. `factors` are non-outcome
    /// trackers; `outcomes` are symptom/mood trackers. Results are sorted by |r| descending,
    /// strongest first. Pairs without enough overlap or with zero variance are dropped.
    static func rankedResults(series: [Series], lag: Int) -> [Result] {
        let outcomes = series.filter { $0.isOutcome }
        let factors = series.filter { !$0.isOutcome }
        var results: [Result] = []

        for factor in factors {
            for outcome in outcomes {
                let paired = pairedSeries(factor: factor.byDay, outcome: outcome.byDay, lag: lag)
                guard let r = pearson(paired.xs, paired.ys) else { continue }
                results.append(Result(factorID: factor.id,
                                      outcomeID: outcome.id,
                                      factorName: factor.name,
                                      outcomeName: outcome.name,
                                      r: r,
                                      n: paired.xs.count,
                                      lag: lag))
            }
        }
        return results.sorted { abs($0.r) > abs($1.r) }
    }

    /// The paired points for one specific finding — used to draw its scatter chart.
    struct ScatterPoint: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
        let day: Date
    }

    static func scatterPoints(factor: [Date: Double], outcome: [Date: Double], lag: Int) -> [ScatterPoint] {
        let paired = pairedSeries(factor: factor, outcome: outcome, lag: lag)
        var points: [ScatterPoint] = []
        for i in 0..<paired.xs.count {
            points.append(ScatterPoint(x: paired.xs[i], y: paired.ys[i], day: paired.days[i]))
        }
        return points
    }
}
