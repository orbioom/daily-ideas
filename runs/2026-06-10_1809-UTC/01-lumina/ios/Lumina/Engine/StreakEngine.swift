import Foundation

/// Streak + practice statistics derived from logged days.
struct StreakStats {
    var current: Int
    var longest: Int
    var totalAffirmed: Int
    var daysPracticed: Int
}

enum StreakEngine {
    private static var cal: Calendar { Calendar.current }

    static func startOfDay(_ d: Date) -> Date { cal.startOfDay(for: d) }

    /// Compute streak stats from logs. `current` counts consecutive days up to
    /// today (or yesterday, if today not yet logged — the streak is still alive).
    static func stats(from logs: [DayLog], today: Date = .now) -> StreakStats {
        let total = logs.reduce(0) { $0 + max(0, $1.count) }
        let practiced = logs.filter { $0.count > 0 }.count
        guard !logs.isEmpty else {
            return StreakStats(current: 0, longest: 0, totalAffirmed: total, daysPracticed: practiced)
        }
        let days = Set(logs.filter { $0.count > 0 }.map { startOfDay($0.day) })
        guard !days.isEmpty else {
            return StreakStats(current: 0, longest: 0, totalAffirmed: total, daysPracticed: practiced)
        }

        // Longest run anywhere in the history.
        let sorted = days.sorted()
        var longest = 1
        var run = 1
        for i in 1..<max(1, sorted.count) {
            if let prev = cal.date(byAdding: .day, value: 1, to: sorted[i-1]),
               prev == sorted[i] {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        if sorted.count == 1 { longest = 1 }

        // Current run, anchored at today or yesterday.
        let t = startOfDay(today)
        var cursor = t
        if !days.contains(t) {
            // allow grace: if not done today, start from yesterday
            cursor = cal.date(byAdding: .day, value: -1, to: t) ?? t
            if !days.contains(cursor) {
                return StreakStats(current: 0, longest: longest, totalAffirmed: total, daysPracticed: practiced)
            }
        }
        var current = 0
        while days.contains(cursor) {
            current += 1
            guard let p = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = p
        }
        return StreakStats(current: current, longest: max(longest, current),
                           totalAffirmed: total, daysPracticed: practiced)
    }

    /// Logs for the last `n` days as (date, count), oldest first — for charts.
    static func recent(_ logs: [DayLog], days n: Int, today: Date = .now) -> [(date: Date, count: Int)] {
        let map = Dictionary(logs.map { (startOfDay($0.day), max(0, $0.count)) }, uniquingKeysWith: +)
        let t = startOfDay(today)
        return (0..<n).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: t) ?? t
            return (d, map[d] ?? 0)
        }
    }
}
