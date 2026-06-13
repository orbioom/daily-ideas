import Foundation

enum MosaicStats {
    private static var cal: Calendar { Calendar.current }

    static func daySet(_ entries: [DayEntry]) -> Set<Date> {
        Set(entries.map { cal.startOfDay(for: $0.day) })
    }

    /// Consecutive days with an entry, counting back from today (or yesterday).
    static func currentStreak(_ entries: [DayEntry]) -> Int {
        let days = daySet(entries)
        guard !days.isEmpty else { return 0 }
        let today = cal.startOfDay(for: .now)
        var cursor = today
        if !days.contains(today) {
            guard let y = cal.date(byAdding: .day, value: -1, to: today), days.contains(y) else { return 0 }
            cursor = y
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func longestStreak(_ entries: [DayEntry]) -> Int {
        let days = daySet(entries).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1, run = 1
        for i in 1..<days.count {
            if let diff = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day, diff == 1 {
                run += 1
            } else { run = 1 }
            longest = max(longest, run)
        }
        return longest
    }

    static func moodCounts(_ entries: [DayEntry]) -> [(mood: Mood, count: Int)] {
        Theme.moods.map { mood in
            (mood, entries.filter { $0.moodIndex == mood.index }.count)
        }
    }

    static func averageMood(_ entries: [DayEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.reduce(0) { $0 + $1.moodIndex }) / Double(entries.count)
    }

    /// "On this day" — entries from notable past intervals that have content.
    static func memories(_ entries: [DayEntry], today: Date = .now) -> [DayEntry] {
        let byDay = Dictionary(uniqueKeysWithValues: entries.map { (cal.startOfDay(for: $0.day), $0) })
        let base = cal.startOfDay(for: today)
        var results: [DayEntry] = []
        let backsets: [(Calendar.Component, Int)] = [(.day, -7), (.month, -1), (.month, -3), (.month, -6), (.year, -1), (.year, -2)]
        for (comp, value) in backsets {
            if let d = cal.date(byAdding: comp, value: value, to: base),
               let entry = byDay[cal.startOfDay(for: d)] {
                results.append(entry)
            }
        }
        return results
    }

    static func entriesInYear(_ entries: [DayEntry], year: Int) -> [Date: DayEntry] {
        var map: [Date: DayEntry] = [:]
        for e in entries where cal.component(.year, from: e.day) == year {
            map[cal.startOfDay(for: e.day)] = e
        }
        return map
    }

    static func availableYears(_ entries: [DayEntry]) -> [Int] {
        let years = Set(entries.map { cal.component(.year, from: $0.day) })
        let current = cal.component(.year, from: .now)
        return Array(years.union([current])).sorted(by: >)
    }
}
