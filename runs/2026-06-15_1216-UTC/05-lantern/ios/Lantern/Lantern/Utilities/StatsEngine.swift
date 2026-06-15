import Foundation

/// Pure, testable aggregation over `GameRecord`s and `DailyResult`s. No SwiftData
/// or SwiftUI imports — callers pass plain arrays of value snapshots.
enum StatsEngine {

    struct LayoutStats: Identifiable {
        let layout: LayoutKind
        var played: Int
        var wins: Int
        var bestTimeSec: Int?     // best (lowest) time among wins
        var avgTimeSec: Int?      // average time among wins
        var id: String { layout.rawValue }
        var winRate: Double { played == 0 ? 0 : Double(wins) / Double(played) }
    }

    struct DailyPoint: Identifiable {
        let date: Date
        let games: Int
        var id: Date { date }
    }

    /// A lightweight value snapshot of a GameRecord (decoupled from SwiftData).
    struct RecordSnapshot {
        let layout: LayoutKind
        let won: Bool
        let durationSec: Int
        let moves: Int
        let date: Date
    }

    // MARK: Per-layout stats

    static func perLayout(_ records: [RecordSnapshot]) -> [LayoutStats] {
        LayoutKind.allCases.map { kind in
            let forKind = records.filter { $0.layout == kind }
            let wins = forKind.filter { $0.won }
            let winTimes = wins.map { $0.durationSec }.filter { $0 > 0 }
            let best = winTimes.min()
            let avg: Int? = winTimes.isEmpty ? nil : winTimes.reduce(0, +) / winTimes.count
            return LayoutStats(
                layout: kind,
                played: forKind.count,
                wins: wins.count,
                bestTimeSec: best,
                avgTimeSec: avg
            )
        }
    }

    static func totalPlayed(_ records: [RecordSnapshot]) -> Int { records.count }
    static func totalWins(_ records: [RecordSnapshot]) -> Int { records.filter { $0.won }.count }

    static func overallWinRate(_ records: [RecordSnapshot]) -> Double {
        guard !records.isEmpty else { return 0 }
        return Double(totalWins(records)) / Double(records.count)
    }

    /// Best win time for a given layout, if any.
    static func bestTime(for layout: LayoutKind, in records: [RecordSnapshot]) -> Int? {
        records.filter { $0.layout == layout && $0.won && $0.durationSec > 0 }
            .map { $0.durationSec }.min()
    }

    // MARK: Games over last N days

    static func gamesPerDay(_ records: [RecordSnapshot], days: Int, calendar: Calendar = .current,
                            now: Date = .now) -> [DailyPoint] {
        guard days > 0 else { return [] }
        let startOfToday = calendar.startOfDay(for: now)
        var points: [DailyPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = records.filter { $0.date >= day && $0.date < nextDay }.count
            points.append(DailyPoint(date: day, games: count))
        }
        return points
    }

    // MARK: Daily streaks

    /// A value snapshot of a DailyResult.
    struct DailySnapshot {
        let dateKey: String
        let won: Bool
    }

    /// Current consecutive-day streak of *won* dailies ending today (or yesterday
    /// if today not yet played). Returns (current, longest).
    static func streaks(_ dailies: [DailySnapshot], calendar: Calendar = .current,
                        now: Date = .now) -> (current: Int, longest: Int) {
        let wonKeys = Set(dailies.filter { $0.won }.map { $0.dateKey })
        guard !wonKeys.isEmpty else { return (0, 0) }

        let fmt = DailyKey.formatter

        // Build the set of won dates.
        let wonDates: Set<Date> = Set(wonKeys.compactMap { key -> Date? in
            guard let d = fmt.date(from: key) else { return nil }
            return calendar.startOfDay(for: d)
        })
        guard !wonDates.isEmpty else { return (0, 0) }

        // Longest streak: scan sorted dates.
        let sorted = wonDates.sorted()
        var longest = 1
        var run = 1
        for i in 1..<max(sorted.count, 1) {
            guard sorted.indices.contains(i), sorted.indices.contains(i - 1) else { break }
            let prev = sorted[i - 1]
            let cur = sorted[i]
            if let next = calendar.date(byAdding: .day, value: 1, to: prev), calendar.isDate(next, inSameDayAs: cur) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        if sorted.count == 1 { longest = 1 }

        // Current streak: count back from today (or yesterday if today not won).
        let today = calendar.startOfDay(for: now)
        var current = 0
        var cursor = today
        if !wonDates.contains(today) {
            // allow streak to be "alive" if yesterday was won
            cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            if !wonDates.contains(cursor) { return (0, longest) }
        }
        while wonDates.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return (current, longest)
    }
}

/// Helpers for the "yyyy-MM-dd" daily key.
enum DailyKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date = .now) -> String { formatter.string(from: date) }
    static func date(from key: String) -> Date? { formatter.date(from: key) }
}
