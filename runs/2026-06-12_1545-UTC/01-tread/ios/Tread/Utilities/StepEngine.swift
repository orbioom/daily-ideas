import Foundation

struct WeekdayAvg: Identifiable {
    let weekday: Int
    let avg: Int
    var id: Int { weekday }
}

/// Pure, testable statistics over a set of `DayLog`s. Holds no state.
enum StepEngine {

    /// Current streak of consecutive goal-met days ending today (or yesterday
    /// if today is not yet complete). A day with no record breaks the streak.
    static func currentStreak(logs: [DayLog], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let byDay = Dictionary(logs.map { (calendar.startOfDay(for: $0.day), $0) },
                               uniquingKeysWith: { a, b in a.steps >= b.steps ? a : b })
        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        // If today hasn't met goal yet, start counting from yesterday so an
        // in-progress day doesn't zero out an otherwise live streak.
        if let t = byDay[cursor], !t.metGoal {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        } else if byDay[cursor] == nil {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while let log = byDay[cursor], log.metGoal {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func longestStreak(logs: [DayLog], calendar: Calendar = .current) -> Int {
        let met = logs.filter { $0.metGoal }
            .map { calendar.startOfDay(for: $0.day) }
            .sorted()
        guard !met.isEmpty else { return 0 }
        var best = 1, run = 1
        for i in 1..<met.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: met[i - 1]),
               calendar.isDate(prev, inSameDayAs: met[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    static func totalSteps(logs: [DayLog]) -> Int { logs.reduce(0) { $0 + $1.steps } }

    static func weekTotal(logs: [DayLog], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: today)) ?? today
        return logs.filter { $0.day >= start }.reduce(0) { $0 + $1.steps }
    }

    static func average(logs: [DayLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        return totalSteps(logs: logs) / logs.count
    }

    static func bestDay(logs: [DayLog]) -> DayLog? { logs.max { $0.steps < $1.steps } }

    static func goalMetCount(logs: [DayLog]) -> Int { logs.filter(\.metGoal).count }

    /// Average steps per weekday (1 = Sunday … 7 = Saturday), for the rhythm chart.
    static func byWeekday(logs: [DayLog], calendar: Calendar = .current) -> [WeekdayAvg] {
        var sums = [Int: (total: Int, count: Int)]()
        for log in logs {
            let wd = calendar.component(.weekday, from: log.day)
            let cur = sums[wd] ?? (0, 0)
            sums[wd] = (cur.total + log.steps, cur.count + 1)
        }
        return (1...7).map { wd in
            let s = sums[wd]
            let avg = (s != nil && s!.count > 0) ? s!.total / s!.count : 0
            return WeekdayAvg(weekday: wd, avg: avg)
        }
    }

    /// Which catalog badges are *currently* earned given the data.
    static func earnedBadgeIDs(logs: [DayLog], today: Date = Date()) -> Set<String> {
        let total = totalSteps(logs: logs)
        let streak = max(currentStreak(logs: logs, today: today), longestStreak(logs: logs))
        let maxDay = logs.map(\.steps).max() ?? 0
        var ids = Set<String>()
        for def in BadgeCatalog.all {
            switch def.kind {
            case .singleDaySteps(let n): if maxDay >= n { ids.insert(def.id) }
            case .streak(let n):         if streak >= n { ids.insert(def.id) }
            case .totalSteps(let n):     if total >= n { ids.insert(def.id) }
            }
        }
        return ids
    }
}
