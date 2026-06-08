import Foundation

/// Pure, testable journaling statistics. No SwiftData, no UI — give it entries
/// and a calendar, get back streaks, word totals, mood trends, and heatmap data.
struct JournalEngine {

    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Distinct journaling days

    /// Set of start-of-day dates that have at least one entry.
    func journaledDays(_ entries: [JournalEntry]) -> Set<Date> {
        Set(entries.map { calendar.startOfDay(for: $0.date) })
    }

    // MARK: - Streaks

    /// Current consecutive-day streak ending today (or yesterday — a streak is
    /// still "alive" if you journaled yesterday but not yet today).
    func currentStreak(_ entries: [JournalEntry], asOf today: Date = .now) -> Int {
        let days = journaledDays(entries)
        guard !days.isEmpty else { return 0 }
        let start = calendar.startOfDay(for: today)
        // Anchor: today if present, else yesterday, else 0.
        var anchor: Date
        if days.contains(start) {
            anchor = start
        } else if let y = calendar.date(byAdding: .day, value: -1, to: start), days.contains(y) {
            anchor = y
        } else {
            return 0
        }
        var count = 0
        var cursor = anchor
        while days.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    /// Longest consecutive-day streak ever recorded.
    func longestStreak(_ entries: [JournalEntry]) -> Int {
        let days = journaledDays(entries).sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<days.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: days[i - 1]),
               calendar.isDate(prev, inSameDayAs: days[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: - Totals

    func totalWords(_ entries: [JournalEntry]) -> Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    func averageMood(_ entries: [JournalEntry]) -> Double? {
        let rated = entries.filter { $0.mood > 0 }
        guard !rated.isEmpty else { return nil }
        let sum = rated.reduce(0) { $0 + $1.mood }
        return Double(sum) / Double(rated.count)
    }

    // MARK: - Mood trend (last N days)

    struct DayMood: Identifiable {
        let id = UUID()
        let day: Date
        let average: Double?   // nil when no rated entries that day
    }

    func moodTrend(_ entries: [JournalEntry], days span: Int, asOf today: Date = .now) -> [DayMood] {
        let start = calendar.startOfDay(for: today)
        var result: [DayMood] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { continue }
            let rated = entries.filter {
                calendar.isDate($0.date, inSameDayAs: day) && $0.mood > 0
            }
            let avg: Double? = rated.isEmpty
                ? nil
                : Double(rated.reduce(0) { $0 + $1.mood }) / Double(rated.count)
            result.append(DayMood(day: day, average: avg))
        }
        return result
    }

    // MARK: - Entries per month (last N months)

    struct MonthCount: Identifiable {
        let id = UUID()
        let month: Date    // first of month
        let count: Int
    }

    func entriesPerMonth(_ entries: [JournalEntry], months span: Int, asOf today: Date = .now) -> [MonthCount] {
        let comps = calendar.dateComponents([.year, .month], from: today)
        guard let thisMonth = calendar.date(from: comps) else { return [] }
        var result: [MonthCount] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let month = calendar.date(byAdding: .month, value: -offset, to: thisMonth) else { continue }
            let count = entries.filter {
                calendar.isDate($0.date, equalTo: month, toGranularity: .month)
            }.count
            result.append(MonthCount(month: month, count: count))
        }
        return result
    }

    // MARK: - "On this day" across past years

    func onThisDay(_ entries: [JournalEntry], reference: Date = .now) -> [JournalEntry] {
        let refComps = calendar.dateComponents([.month, .day], from: reference)
        let refYear = calendar.component(.year, from: reference)
        return entries.filter { e in
            let c = calendar.dateComponents([.month, .day, .year], from: e.date)
            return c.month == refComps.month && c.day == refComps.day && c.year != refYear
        }
        .sorted { $0.date > $1.date }
    }

    // MARK: - Tag usage

    struct TagCount: Identifiable {
        let id = UUID()
        let name: String
        let colorHex: UInt32
        let count: Int
    }

    func tagCounts(_ entries: [JournalEntry]) -> [TagCount] {
        var map: [String: (UInt32, Int)] = [:]
        for e in entries {
            for t in e.tags {
                let existing = map[t.name] ?? (t.colorHex, 0)
                map[t.name] = (t.colorHex, existing.1 + 1)
            }
        }
        return map.map { TagCount(name: $0.key, colorHex: $0.value.0, count: $0.value.1) }
            .sorted { $0.count > $1.count }
    }
}
