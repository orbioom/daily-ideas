import Foundation

/// A single point in a PTA-over-time trend.
struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ear: Ear
    let pta: Double
}

/// Pure analysis over completed tests. No UI, no I/O — fully unit-testable in principle.
enum AnalysisEngine {

    /// Left/right asymmetry in PTA (absolute difference). Returns nil if either side missing.
    static func ptaAsymmetry(left: Double?, right: Double?) -> Double? {
        guard let l = left, let r = right else { return nil }
        return abs(l - r)
    }

    /// Significant asymmetry threshold (relative dB). Asymmetry above this is worth flagging.
    static let significantAsymmetry: Double = 15

    static func asymmetryNote(left: Double?, right: Double?) -> String {
        guard let diff = ptaAsymmetry(left: left, right: right), let l = left, let r = right else {
            return "Asymmetry needs results from both ears."
        }
        if diff < significantAsymmetry {
            return "Your ears are reasonably balanced (within \(Int(significantAsymmetry.rounded())) dB)."
        }
        let weaker = l > r ? "left" : "right"
        return "Your \(weaker) ear screened noticeably weaker (\(Int(diff.rounded())) dB difference). A one-sided difference is worth mentioning to a professional."
    }

    /// Build a trend series (sorted by date) of PTA per ear from completed tests.
    static func trend(from tests: [HearingTest]) -> [TrendPoint] {
        var points: [TrendPoint] = []
        for test in tests.sorted(by: { $0.date < $1.date }) {
            if let l = test.ptaLeft { points.append(TrendPoint(date: test.date, ear: .left, pta: l)) }
            if let r = test.ptaRight { points.append(TrendPoint(date: test.date, ear: .right, pta: r)) }
        }
        return points
    }

    /// Direction of change between earliest and latest PTA for an ear.
    /// Positive delta = thresholds went UP = hearing screened worse.
    static func trendDelta(for ear: Ear, in tests: [HearingTest]) -> Double? {
        let sorted = tests.sorted(by: { $0.date < $1.date })
        let series = sorted.compactMap { ear == .left ? $0.ptaLeft : $0.ptaRight }
        guard let first = series.first, let last = series.last, series.count >= 2 else { return nil }
        return last - first
    }

    static func trendSummary(for ear: Ear, in tests: [HearingTest]) -> String {
        guard let delta = trendDelta(for: ear, in: tests) else {
            return "Run a few tests over time to see a trend."
        }
        if abs(delta) < 5 {
            return "\(ear.rawValue) ear has held steady across your tests."
        }
        if delta > 0 {
            return "\(ear.rawValue) ear PTA rose \(Int(delta.rounded())) dB — thresholds drifted higher. Keep an eye on it."
        }
        return "\(ear.rawValue) ear PTA improved \(Int(abs(delta).rounded())) dB since your first test."
    }
}
