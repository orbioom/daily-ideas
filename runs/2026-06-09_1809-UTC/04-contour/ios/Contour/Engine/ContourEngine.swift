import Foundation

/// Pure, static analysis over body metrics & progress photos. Every aggregate
/// guards empty series and zero/sign-degenerate slopes so user paths never hit
/// an unguarded division or force-unwrap.
enum ContourEngine {

    // MARK: - Shared value types

    /// A single point in a time series (used for charts).
    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    /// Summary of a single metric type's history.
    struct MetricSummary {
        let type: MetricType
        let current: Double          // canonical
        let starting: Double         // canonical
        let delta: Double            // current - starting
        let percentChange: Double?   // nil if starting == 0
        let series: [Point]          // chronological, canonical
        var hasData: Bool { !series.isEmpty }
    }

    /// Weight-specific trend bundle.
    struct WeightTrend {
        let raw: [Point]                 // chronological raw weights (kg)
        let ema: [Point]                 // EMA-smoothed (kg)
        let changeSinceStart: Double?    // kg, nil if <1 point
        let change30d: Double?           // kg over last 30 days, nil if insufficient
        let ratePerWeek: Double?         // kg/week least-squares slope, nil if <2 points
        let projectedDateToGoal: Date?   // nil if no goal / slope wrong sign / flat
        let projectedWeightAtDate: Double? // projected kg at goal date, nil if no rate
    }

    // MARK: - Generic helpers

    /// Sorts metrics of a type chronologically and maps to points.
    static func series(for type: MetricType, in metrics: [BodyMetric]) -> [Point] {
        metrics
            .filter { $0.type == type }
            .sorted { $0.date < $1.date }
            .map { Point(date: $0.date, value: $0.value) }
    }

    /// Exponential moving average over a chronological series. `alpha` in (0,1].
    static func ema(_ points: [Point], alpha: Double = 0.3) -> [Point] {
        guard !points.isEmpty else { return [] }
        let a = min(max(alpha, 0.01), 1)
        var result: [Point] = []
        var prev = points[0].value
        for (i, p) in points.enumerated() {
            let smoothed = i == 0 ? p.value : a * p.value + (1 - a) * prev
            prev = smoothed
            result.append(Point(date: p.date, value: smoothed))
        }
        return result
    }

    /// Least-squares slope of value vs. time, expressed per week. Nil if <2 points
    /// or zero time span (guards division).
    static func slopePerWeek(_ points: [Point]) -> Double? {
        guard points.count >= 2 else { return nil }
        guard let first = points.first?.date else { return nil }
        // x in days since first point, y = value.
        let xs = points.map { $0.date.timeIntervalSince(first) / 86_400.0 }
        let ys = points.map { $0.value }
        let n = Double(points.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let meanX = sumX / n
        let meanY = sumY / n
        var num = 0.0
        var den = 0.0
        for i in xs.indices {
            let dx = xs[i] - meanX
            num += dx * (ys[i] - meanY)
            den += dx * dx
        }
        guard den > 0 else { return nil }   // all points same day
        let perDay = num / den
        return perDay * 7.0
    }

    // MARK: - Metric summaries

    static func summary(for type: MetricType, in metrics: [BodyMetric]) -> MetricSummary {
        let pts = series(for: type, in: metrics)
        guard let start = pts.first?.value, let end = pts.last?.value else {
            return MetricSummary(type: type, current: 0, starting: 0, delta: 0,
                                 percentChange: nil, series: [])
        }
        let delta = end - start
        let pct: Double? = abs(start) > 0.0001 ? (delta / start) * 100 : nil
        return MetricSummary(type: type, current: end, starting: start,
                             delta: delta, percentChange: pct, series: pts)
    }

    /// Summaries for every metric type that has at least one reading.
    static func allSummaries(in metrics: [BodyMetric]) -> [MetricSummary] {
        MetricType.allCases
            .map { summary(for: $0, in: metrics) }
            .filter { $0.hasData }
    }

    // MARK: - Weight trend

    static func weightTrend(in metrics: [BodyMetric],
                            goalWeightKg: Double?,
                            now: Date = .now) -> WeightTrend {
        let raw = series(for: .weight, in: metrics)
        guard !raw.isEmpty else {
            return WeightTrend(raw: [], ema: [], changeSinceStart: nil,
                               change30d: nil, ratePerWeek: nil,
                               projectedDateToGoal: nil, projectedWeightAtDate: nil)
        }
        let smoothed = ema(raw)
        let changeSinceStart: Double? = {
            guard raw.count >= 2, let firstV = raw.first?.value, let lastV = raw.last?.value else { return nil }
            return lastV - firstV
        }()

        // Change over last 30 days: anchor on the earliest point within the window.
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let windowPts = raw.filter { $0.date >= cutoff }
        let change30d: Double? = {
            guard let last = raw.last else { return nil }
            guard let anchor = windowPts.first, windowPts.count >= 2 else { return nil }
            return last.value - anchor.value
        }()

        let rate = slopePerWeek(raw)

        // Projection: how many weeks until we reach the goal, given current rate.
        var projectedDate: Date? = nil
        if let rate, let last = raw.last {
            // Project current EMA value forward at the rate.
            let currentValue = smoothed.last?.value ?? last.value
            if let goal = goalWeightKg {
                let remaining = goal - currentValue
                // Need slope sign to actually move toward the goal, and non-zero.
                if abs(rate) > 0.0001, remaining * rate > 0 || abs(remaining) < 0.05 {
                    let weeks = abs(remaining) < 0.05 ? 0 : remaining / rate
                    if weeks >= 0, weeks.isFinite {
                        projectedDate = Calendar.current.date(byAdding: .day,
                                                              value: Int((weeks * 7).rounded()),
                                                              to: now)
                    }
                }
            }
        }

        // Projected weight at a specific target date is computed on demand via
        // projectedWeight(at:); default nil in the bundled trend.
        return WeightTrend(raw: raw, ema: smoothed,
                           changeSinceStart: changeSinceStart,
                           change30d: change30d, ratePerWeek: rate,
                           projectedDateToGoal: projectedDate,
                           projectedWeightAtDate: nil)
    }

    /// Projected canonical weight (kg) at a target date given the current rate.
    /// Nil if no rate or the date is in the past.
    static func projectedWeight(at target: Date, in metrics: [BodyMetric], now: Date = .now) -> Double? {
        let raw = series(for: .weight, in: metrics)
        guard let rate = slopePerWeek(raw), let last = raw.last else { return nil }
        let weeks = target.timeIntervalSince(now) / (7 * 86_400.0)
        guard weeks.isFinite, weeks >= 0 else { return nil }
        let base = ema(raw).last?.value ?? last.value
        let projected = base + rate * weeks
        return projected.isFinite ? max(0, projected) : nil
    }

    // MARK: - Photo timeline

    struct MonthGroup: Identifiable {
        let id = UUID()
        let monthStart: Date
        let title: String
        let photos: [ProgressPhoto]   // newest first within the month
    }

    /// Groups photos by month, newest month first.
    static func groupByMonth(_ photos: [ProgressPhoto]) -> [MonthGroup] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: photos) { photo -> Date in
            cal.date(from: cal.dateComponents([.year, .month], from: photo.date)) ?? photo.date
        }
        return grouped
            .map { key, value in
                MonthGroup(monthStart: key,
                           title: Format.monthYear.string(from: key),
                           photos: value.sorted { $0.date > $1.date })
            }
            .sorted { $0.monthStart > $1.monthStart }
    }

    /// Total span in days between the earliest and latest of any dated items.
    static func spanDays(photos: [ProgressPhoto], metrics: [BodyMetric]) -> Int {
        var dates: [Date] = photos.map { $0.date }
        dates.append(contentsOf: metrics.map { $0.date })
        guard let min = dates.min(), let max = dates.max() else { return 0 }
        return max(daysBetween(min, max), 0)
    }

    /// Consecutive-day logging streak ending today (or yesterday-tolerant):
    /// counts back day-by-day while each day has a photo OR a metric.
    static func loggingStreak(photos: [ProgressPhoto], metrics: [BodyMetric], now: Date = .now) -> Int {
        let cal = Calendar.current
        var loggedDays = Set<Date>()
        for p in photos { loggedDays.insert(cal.startOfDay(for: p.date)) }
        for m in metrics { loggedDays.insert(cal.startOfDay(for: m.date)) }
        guard !loggedDays.isEmpty else { return 0 }

        // Allow the streak to "start" today or yesterday (logging once a day is fine).
        var cursor = cal.startOfDay(for: now)
        if !loggedDays.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  loggedDays.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while loggedDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    // MARK: - Compare

    struct Comparison {
        let pose: Pose
        let before: ProgressPhoto
        let after: ProgressPhoto
        let daysBetween: Int
        let weightDelta: Double?   // kg, nil if either side lacks a weight
    }

    /// Earliest & latest photos for a pose, plus span and weight delta. Nil if
    /// fewer than two photos exist for that pose.
    static func comparison(for pose: Pose, photos: [ProgressPhoto]) -> Comparison? {
        let withImage = photos
            .filter { $0.pose == pose && $0.hasImage }
            .sorted { $0.date < $1.date }
        guard withImage.count >= 2,
              let before = withImage.first,
              let after = withImage.last else { return nil }
        let days = daysBetween(before.date, after.date)
        let delta: Double? = {
            guard let w0 = before.weightAtTime, let w1 = after.weightAtTime else { return nil }
            return w1 - w0
        }()
        return Comparison(pose: pose, before: before, after: after,
                          daysBetween: days, weightDelta: delta)
    }

    // MARK: - Utilities

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let cal = Calendar.current
        let d = cal.dateComponents([.day], from: cal.startOfDay(for: a),
                                   to: cal.startOfDay(for: b)).day ?? 0
        return abs(d)
    }
}
