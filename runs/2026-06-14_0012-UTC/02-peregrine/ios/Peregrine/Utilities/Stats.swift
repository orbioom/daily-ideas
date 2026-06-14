import Foundation

/// Pure aggregate computations over progress + session data. No SwiftData here —
/// callers pass plain arrays/snapshots so this is trivially testable and never
/// touches the main-actor store directly.
enum Stats {

    /// Overall mastery 0...1 across the whole dataset (unseen countries count as
    /// zero, so the number reflects true coverage, not just answered items).
    static func overallMastery(progressByISO: [String: Double]) -> Double {
        let total = CountryData.all.count
        guard total > 0 else { return 0 }
        let sum = CountryData.all.reduce(0.0) { acc, c in
            acc + (progressByISO[c.iso2] ?? 0)
        }
        return sum / Double(total)
    }

    /// Average mastery per continent (0...1), unseen as zero.
    static func continentMastery(progressByISO: [String: Double]) -> [Continent: Double] {
        var result: [Continent: Double] = [:]
        for continent in Continent.displayOrder {
            let members = CountryData.countries(in: continent)
            guard !members.isEmpty else { result[continent] = 0; continue }
            let sum = members.reduce(0.0) { $0 + (progressByISO[$1.iso2] ?? 0) }
            result[continent] = sum / Double(members.count)
        }
        return result
    }

    /// Count of countries whose mastery clears the "mastered" threshold (0.7).
    static func masteredCount(progressByISO: [String: Double]) -> Int {
        CountryData.all.reduce(0) { acc, c in
            acc + ((progressByISO[c.iso2] ?? 0) >= 0.7 ? 1 : 0)
        }
    }

    /// Current daily streak: consecutive calendar days (ending today or
    /// yesterday) on which at least one session was completed.
    static func currentStreak(sessionDates: [Date],
                              calendar: Calendar = .current,
                              now: Date = Date()) -> Int {
        guard !sessionDates.isEmpty else { return 0 }
        let days = Set(sessionDates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)
        // Streak may end today or yesterday (so an unfinished today doesn't break it).
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Best (longest-ever) streak across all session dates.
    static func bestStreak(sessionDates: [Date], calendar: Calendar = .current) -> Int {
        guard !sessionDates.isEmpty else { return 0 }
        let days = Set(sessionDates.map { calendar.startOfDay(for: $0) }).sorted()
        var best = 1
        var run = 1
        for i in 1..<days.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: days[i - 1]),
               prev == days[i] {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }
}
