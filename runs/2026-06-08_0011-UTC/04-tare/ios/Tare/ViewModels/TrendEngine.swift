import Foundation

/// The smoothed-trend analytics that make a noisy scale readable — an
/// exponentially weighted moving average plus a least-squares rate and a
/// projection to goal. All maths is on-device and unit-agnostic (kilograms).
struct TrendEngine {
    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let raw: Double      // kg
        let trend: Double    // kg, smoothed
    }

    let points: [Point]
    let currentTrend: Double?
    let currentRaw: Double?
    let startTrend: Double?
    /// kg per week (negative = losing). Nil if not enough data.
    let ratePerWeek: Double?

    var totalChange: Double? {
        guard let c = currentTrend, let s = startTrend else { return nil }
        return c - s
    }

    /// Build trend from chronological entries.
    /// - alpha: smoothing factor (Happy Scale-style ~0.1). Higher = follows the
    ///   scale faster; lower = smoother trend.
    static func build(entries: [WeightEntry], alpha: Double = 0.1, rateWindowDays: Int = 30, now: Date = .now) -> TrendEngine {
        let sorted = entries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else {
            return TrendEngine(points: [], currentTrend: nil, currentRaw: nil, startTrend: nil, ratePerWeek: nil)
        }
        var pts: [Point] = []
        var trend = sorted[0].kilograms
        for (i, e) in sorted.enumerated() {
            if i == 0 {
                trend = e.kilograms
            } else {
                trend += alpha * (e.kilograms - trend)
            }
            pts.append(Point(date: e.date, raw: e.kilograms, trend: trend))
        }

        // Rate via least-squares slope of trend over the recent window.
        let cutoff = Calendar.current.date(byAdding: .day, value: -rateWindowDays, to: now) ?? now
        let window = pts.filter { $0.date >= cutoff }
        let rate: Double?
        if window.count >= 2 {
            let t0 = window.first!.date.timeIntervalSince1970
            let xs = window.map { ($0.date.timeIntervalSince1970 - t0) / 86400.0 } // days
            let ys = window.map { $0.trend }
            rate = slope(xs, ys).map { $0 * 7.0 }   // per week
        } else {
            rate = nil
        }

        return TrendEngine(points: pts,
                           currentTrend: pts.last?.trend,
                           currentRaw: pts.last?.raw,
                           startTrend: pts.first?.trend,
                           ratePerWeek: rate)
    }

    /// Days until the trend reaches `goalKg`, given the current weekly rate.
    /// Returns nil if the trend is flat or moving away from the goal.
    func daysToGoal(_ goalKg: Double) -> Int? {
        guard let current = currentTrend, let rate = ratePerWeek, abs(rate) > 0.001 else { return nil }
        let remaining = goalKg - current               // signed
        let perDay = rate / 7.0
        // Must be moving in the same direction as remaining.
        guard (remaining < 0 && perDay < 0) || (remaining > 0 && perDay > 0) else { return nil }
        let days = remaining / perDay
        guard days.isFinite, days >= 0, days < 3650 else { return nil }
        return Int(days.rounded())
    }

    func projectedDate(_ goalKg: Double, now: Date = .now) -> Date? {
        guard let days = daysToGoal(goalKg) else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: now)
    }

    static func bmi(kg: Double, heightCm: Double) -> Double? {
        guard heightCm > 0 else { return nil }
        let m = heightCm / 100
        return kg / (m * m)
    }

    static func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Healthy"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    // MARK: - least squares
    private static func slope(_ xs: [Double], _ ys: [Double]) -> Double? {
        let n = Double(xs.count)
        guard n >= 2 else { return nil }
        let sx = xs.reduce(0, +), sy = ys.reduce(0, +)
        let sxx = zip(xs, xs).reduce(0) { $0 + $1.0 * $1.1 }
        let sxy = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let denom = n * sxx - sx * sx
        guard abs(denom) > 1e-9 else { return nil }
        return (n * sxy - sx * sy) / denom
    }
}
