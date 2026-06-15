import Foundation

/// Per-tracker descriptive statistics computed in plain Swift from a tracker's log entries.
/// Everything guards against empty input and zero-variance so no division can crash.
enum StatsEngine {

    /// A snapshot of one tracker's recent behaviour.
    struct Summary {
        let count: Int                 // number of logged days in window
        let current: Double?           // most recent value (any time)
        let average7: Double?          // rolling 7-day mean
        let average30: Double?         // rolling 30-day mean
        let minValue: Double?
        let maxValue: Double?
        let streak: Int                // consecutive days logged up to today
        let slope: Double?             // least-squares slope per day (trend)
        let trend: Trend

        static let empty = Summary(count: 0, current: nil, average7: nil, average30: nil,
                                   minValue: nil, maxValue: nil, streak: 0, slope: nil, trend: .flat)
    }

    enum Trend {
        case rising, falling, flat

        var symbol: String {
            switch self {
            case .rising: return "arrow.up.right"
            case .falling: return "arrow.down.right"
            case .flat: return "arrow.right"
            }
        }

        var label: String {
            switch self {
            case .rising: return "Rising"
            case .falling: return "Falling"
            case .flat: return "Steady"
            }
        }
    }

    /// Compute a summary for one tracker from its (date, value) points. `points` need not be
    /// sorted. `now` is injectable for tests/previews.
    static func summary(points: [(date: Date, value: Double)], now: Date = Date()) -> Summary {
        guard !points.isEmpty else { return .empty }
        let sorted = points.sorted { $0.date < $1.date }

        let values = sorted.map(\.value)
        let current = sorted.last?.value
        let minValue = values.min()
        let maxValue = values.max()

        let avg7 = mean(valuesWithin(days: 7, of: sorted, now: now))
        let avg30 = mean(valuesWithin(days: 30, of: sorted, now: now))

        let streak = loggingStreak(dates: sorted.map(\.date), now: now)
        let slope = leastSquaresSlope(sorted)
        let trend = trendFromSlope(slope, valueSpread: (maxValue ?? 0) - (minValue ?? 0))

        return Summary(count: sorted.count,
                       current: current,
                       average7: avg7,
                       average30: avg30,
                       minValue: minValue,
                       maxValue: maxValue,
                       streak: streak,
                       slope: slope,
                       trend: trend)
    }

    // MARK: Helpers

    static func mean(_ xs: [Double]) -> Double? {
        guard !xs.isEmpty else { return nil }
        return xs.reduce(0, +) / Double(xs.count)
    }

    private static func valuesWithin(days: Int, of sorted: [(date: Date, value: Double)], now: Date) -> [Double] {
        guard days > 0 else { return [] }
        let cutoff = DayMath.calendar.date(byAdding: .day, value: -(days - 1), to: DayMath.startOfDay(now)) ?? now
        return sorted.filter { $0.date >= cutoff }.map(\.value)
    }

    /// Consecutive calendar days with a log, counting back from today (or yesterday if today
    /// isn't logged yet — a streak shouldn't break just because it's early in the day).
    static func loggingStreak(dates: [Date], now: Date = Date()) -> Int {
        guard !dates.isEmpty else { return 0 }
        let logged = Set(dates.map { DayMath.startOfDay($0) })
        let today = DayMath.startOfDay(now)

        var anchor = today
        if !logged.contains(today) {
            guard let yesterday = DayMath.calendar.date(byAdding: .day, value: -1, to: today),
                  logged.contains(yesterday) else { return 0 }
            anchor = yesterday
        }

        var streak = 0
        var cursor = anchor
        while logged.contains(cursor) {
            streak += 1
            guard let prev = DayMath.calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Least-squares slope of value over day-index. Returns nil if fewer than 2 points or if the
    /// x-values have zero variance (can't fit a line).
    static func leastSquaresSlope(_ sorted: [(date: Date, value: Double)]) -> Double? {
        guard sorted.count >= 2, let first = sorted.first?.date else { return nil }
        let xs = sorted.map { Double(DayMath.dayDelta(from: first, to: $0.date)) }
        let ys = sorted.map(\.value)
        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let meanX = sumX / n
        let meanY = sumY / n
        var num = 0.0, den = 0.0
        for i in 0..<xs.count {
            let dx = xs[i] - meanX
            num += dx * (ys[i] - meanY)
            den += dx * dx
        }
        guard den > 1e-9 else { return nil }
        return num / den
    }

    private static func trendFromSlope(_ slope: Double?, valueSpread: Double) -> Trend {
        guard let slope else { return .flat }
        // A meaningful trend is one whose per-day drift is at least ~1% of the value range.
        let threshold = max(0.01, valueSpread * 0.01)
        if slope > threshold { return .rising }
        if slope < -threshold { return .falling }
        return .flat
    }
}
