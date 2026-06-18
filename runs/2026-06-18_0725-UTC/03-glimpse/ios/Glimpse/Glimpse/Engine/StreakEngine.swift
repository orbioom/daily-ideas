import Foundation

struct StreakStats: Equatable {
    var current: Int
    var longest: Int
    var totalDays: Int
    /// 0...1 share of days in the current month that have a moment.
    var monthCapture: Double
    /// 0...1 share of days so far this year that have a moment.
    var yearCapture: Double
}

/// Pure streak/coverage math over a set of moments. No SwiftData, no UI.
enum StreakEngine {
    static func compute(moments: [Moment], today: Date = Date(), calendar: Calendar = .current) -> StreakStats {
        // Distinct logged day keys.
        let loggedKeys = Set(moments.map { $0.dayKey })
        let totalDays = loggedKeys.count

        let longest = longestStreak(keys: loggedKeys)
        let current = currentStreak(keys: loggedKeys, today: today, calendar: calendar)

        let monthCapture = capture(
            keys: loggedKeys,
            unit: .month,
            today: today,
            calendar: calendar
        )
        let yearCapture = capture(
            keys: loggedKeys,
            unit: .year,
            today: today,
            calendar: calendar
        )

        return StreakStats(
            current: current,
            longest: longest,
            totalDays: totalDays,
            monthCapture: monthCapture,
            yearCapture: yearCapture
        )
    }

    /// Counts consecutive days ending today (or yesterday — grace so the streak
    /// doesn't read as broken before you've captured today's moment).
    static func currentStreak(keys: Set<String>, today: Date, calendar: Calendar) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        var cursor: Date
        if keys.contains(DayKey.key(for: todayStart)) {
            cursor = todayStart
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart),
                  keys.contains(DayKey.key(for: yesterday)) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while keys.contains(DayKey.key(for: cursor)) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    static func longestStreak(keys: Set<String>) -> Int {
        guard !keys.isEmpty else { return 0 }
        // Convert to sortable dates, ignore malformed keys.
        let days = keys.compactMap { DayKey.date(from: $0) }
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()
        guard let first = days.first else { return 0 }

        var best = 1
        var run = 1
        var previous = first
        let cal = Calendar.current
        for day in days.dropFirst() {
            let gap = cal.dateComponents([.day], from: previous, to: day).day ?? 0
            if gap == 1 {
                run += 1
                best = max(best, run)
            } else if gap > 1 {
                run = 1
            }
            previous = day
        }
        return best
    }

    private enum Unit { case month, year }

    private static func capture(keys: Set<String>, unit: Unit, today: Date, calendar: Calendar) -> Double {
        let comps: Set<Calendar.Component> = unit == .month ? [.year, .month] : [.year]
        let nowComps = calendar.dateComponents(comps, from: today)

        // Denominator: number of days elapsed in the period up to today.
        let dayOfMonth = calendar.component(.day, from: today)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        let denom = max(1, unit == .month ? dayOfMonth : dayOfYear)

        var hit = 0
        for key in keys {
            guard let date = DayKey.date(from: key) else { continue }
            guard date <= today else { continue }
            let c = calendar.dateComponents(comps, from: date)
            if c == nowComps { hit += 1 }
        }
        return min(1, Double(hit) / Double(denom))
    }
}
