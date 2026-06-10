import Foundation

/// Pure statistics over the gratitude log. No I/O.
enum PlentyEngine {

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 2026) * 10_000 + (c.month ?? 1) * 100 + (c.day ?? 1)
    }

    /// A "practiced" day is one with any content. Streak counts consecutive
    /// practiced days ending today (or yesterday if today isn't done yet).
    static func currentStreak(days: [GratitudeDay], now: Date = .now, calendar: Calendar = .current) -> Int {
        let practiced = Set(days.filter { $0.hasAnyContent }.map { calendar.startOfDay(for: $0.date) })
        guard !practiced.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: now)
        if !practiced.contains(cursor) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: cursor), practiced.contains(y) else { return 0 }
            cursor = y
        }
        var streak = 0
        while practiced.contains(cursor) {
            streak += 1
            guard let p = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = p
        }
        return streak
    }

    static func entriesCount(days: [GratitudeDay]) -> Int {
        days.filter { $0.hasAnyContent }.count
    }

    static func totalGratitudes(days: [GratitudeDay]) -> Int {
        days.reduce(0) { $0 + $1.filledGratitudes.count + $1.filledWins.count }
    }

    static func totalWords(days: [GratitudeDay]) -> Int {
        days.reduce(0) { $0 + $1.wordCount }
    }

    /// Average mood over days that recorded one, for the last `span` days.
    static func moodTrend(days: [GratitudeDay], span: Int = 30, now: Date = .now,
                          calendar: Calendar = .current) -> [(date: Date, mood: Int?)] {
        let today = calendar.startOfDay(for: now)
        let byDay = Dictionary(uniqueKeysWithValues: days.map { (calendar.startOfDay(for: $0.date), $0) })
        return (0..<span).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let m = byDay[day]?.mood ?? 0
            return (day, m == 0 ? nil : m)
        }
    }

    static func averageMood(days: [GratitudeDay]) -> Double? {
        let moods = days.map { $0.mood }.filter { $0 > 0 }
        guard !moods.isEmpty else { return nil }
        return Double(moods.reduce(0, +)) / Double(moods.count)
    }

    /// Most frequently mentioned meaningful words across all gratitudes/wins.
    static func topWords(days: [GratitudeDay], limit: Int = 8) -> [(word: String, count: Int)] {
        var counts: [String: Int] = [:]
        let stop = Set(["the","a","an","and","or","for","to","of","my","i","is","was","with","that","this",
                        "it","in","on","at","be","am","are","so","very","really","just","today","being",
                        "have","had","has","get","got","being","able","good","great","new","more","much",
                        "able","being","than","then","but","because","about","into","from","they","them",
                        "we","our","you","your","me","he","she","his","her"])
        for day in days {
            let text = (day.morningGratitudes + day.eveningWins).joined(separator: " ").lowercased()
            for raw in text.split(whereSeparator: { !$0.isLetter }) {
                let w = String(raw)
                guard w.count >= 3, !stop.contains(w) else { continue }
                counts[w, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }
            .prefix(limit).map { ($0.key, $0.value) }
    }
}
