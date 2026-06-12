import Foundation

struct MoodCount: Identifiable { let mood: DreamMood; let count: Int; var id: DreamMood { mood } }
struct DayRecall: Identifiable { let day: Date; let count: Int; let lucid: Int; var id: Date { day } }
struct TechniqueStat: Identifiable { let technique: DreamTechnique; let total: Int; let lucid: Int; var id: DreamTechnique { technique } }

enum DreamEngine {

    static func lucidityRate(_ dreams: [Dream]) -> Double {
        guard !dreams.isEmpty else { return 0 }
        return Double(dreams.filter(\.isLucid).count) / Double(dreams.count)
    }

    static func lucidCount(_ dreams: [Dream]) -> Int { dreams.filter(\.isLucid).count }

    static func averageVividness(_ dreams: [Dream]) -> Double {
        guard !dreams.isEmpty else { return 0 }
        return Double(dreams.reduce(0) { $0 + $1.vividness }) / Double(dreams.count)
    }

    /// Consecutive days (ending today or yesterday) with at least one recalled
    /// dream — the "recall streak" that lucid practitioners care about.
    static func recallStreak(_ dreams: [Dream], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = Set(dreams.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: today)
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func dreamsThisWeek(_ dreams: [Dream], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: today)) ?? today
        return dreams.filter { $0.date >= start }.count
    }

    static func moodBreakdown(_ dreams: [Dream]) -> [MoodCount] {
        var d = [DreamMood: Int]()
        for dr in dreams { d[dr.mood, default: 0] += 1 }
        return DreamMood.allCases.compactMap { m in d[m].map { MoodCount(mood: m, count: $0) } }
            .filter { $0.count > 0 }
    }

    static func topSigns(_ signs: [DreamSign], limit: Int = 8) -> [DreamSign] {
        signs.filter { $0.count > 0 }.sorted { $0.count > $1.count }.prefix(limit).map { $0 }
    }

    /// Lucidity rate by technique, to surface what is working for the user.
    static func techniqueEffectiveness(_ dreams: [Dream]) -> [TechniqueStat] {
        var totals = [DreamTechnique: (Int, Int)]()
        for d in dreams where d.technique != .none {
            var cur = totals[d.technique] ?? (0, 0)
            cur.0 += 1
            if d.isLucid { cur.1 += 1 }
            totals[d.technique] = cur
        }
        return totals.map { TechniqueStat(technique: $0.key, total: $0.value.0, lucid: $0.value.1) }
            .sorted { $0.total > $1.total }
    }

    /// Daily dream-recall counts over the last `n` days (oldest first).
    static func dailyCounts(_ dreams: [Dream], days n: Int, today: Date = Date(),
                            calendar: Calendar = .current) -> [DayRecall] {
        let start = calendar.startOfDay(for: today)
        return (0..<n).reversed().compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let dayDreams = dreams.filter { calendar.isDate($0.date, inSameDayAs: d) }
            return DayRecall(day: d, count: dayDreams.count, lucid: dayDreams.filter(\.isLucid).count)
        }
    }
}
