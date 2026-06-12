import Foundation

struct DayReps: Identifiable { let day: Date; let reps: Int; var id: Date { day } }

enum PracticeEngine {

    /// All logs across all active intentions for a given day.
    static func reps(on day: Date, intentions: [Intention], calendar: Calendar = .current) -> Int {
        intentions.compactMap { $0.log(for: day) }.reduce(0) { $0 + $1.totalReps }
    }

    /// Consecutive days (ending today or yesterday) where *every* active
    /// intention's practice was completed.
    static func streak(intentions: [Intention], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let active = intentions.filter { $0.state == .active }
        guard !active.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: today)
        // Don't break the streak just because today isn't finished yet.
        if !allComplete(active, on: cursor, calendar: calendar) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while allComplete(active, on: cursor, calendar: calendar) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private static func allComplete(_ intentions: [Intention], on day: Date, calendar: Calendar) -> Bool {
        // Only count days on/after the earliest intention was created.
        for i in intentions {
            guard calendar.startOfDay(for: i.createdAt) <= day else { continue }
            guard let log = i.log(for: day, calendar: calendar), log.isComplete else { return false }
        }
        // At least one intention must have existed on that day.
        return intentions.contains { calendar.startOfDay(for: $0.createdAt) <= day }
    }

    static func totalReps(_ intentions: [Intention]) -> Int {
        intentions.flatMap(\.logs).reduce(0) { $0 + $1.totalReps }
    }

    static func daysPracticed(_ intentions: [Intention], calendar: Calendar = .current) -> Int {
        let days = Set(intentions.flatMap(\.logs).filter { $0.totalReps > 0 }.map { calendar.startOfDay(for: $0.day) })
        return days.count
    }

    static func manifestedCount(_ intentions: [Intention]) -> Int {
        intentions.filter { $0.state == .manifested }.count
    }

    /// Daily total reps over the last `n` days, oldest first, for the trend chart.
    static func dailyRepSeries(_ intentions: [Intention], days n: Int, today: Date = Date(),
                               calendar: Calendar = .current) -> [DayReps] {
        let start = calendar.startOfDay(for: today)
        return (0..<n).reversed().compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            return DayReps(day: d, reps: reps(on: d, intentions: intentions, calendar: calendar))
        }
    }
}

/// Normalized fuzzy match so the writing ritual accepts close-enough lines
/// (a stray space or capital shouldn't reject a heartfelt affirmation).
enum TextMatch {
    static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters)
    }

    /// 0...1 similarity using normalized Levenshtein distance.
    static func similarity(_ a: String, _ b: String) -> Double {
        let x = Array(normalize(a)), y = Array(normalize(b))
        if x.isEmpty && y.isEmpty { return 1 }
        let dist = levenshtein(x, y)
        let maxLen = max(x.count, y.count)
        guard maxLen > 0 else { return 1 }
        return 1 - Double(dist) / Double(maxLen)
    }

    static func matches(_ written: String, target: String, threshold: Double = 0.82) -> Bool {
        similarity(written, target) >= threshold
    }

    private static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var cur = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            cur[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &cur)
        }
        return prev[b.count]
    }
}
