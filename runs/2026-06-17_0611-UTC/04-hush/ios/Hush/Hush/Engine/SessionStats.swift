import Foundation

/// Pure, testable aggregations over `ListeningSession`s for the Sessions screen.
/// All functions guard against empty input and divide-by-zero.
enum SessionStats {

    struct NightlyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
    }

    struct SoundCount: Identifiable {
        let id: String
        let type: SoundType
        let count: Int
    }

    /// Total listening time across all sessions, in seconds.
    static func totalSeconds(_ sessions: [ListeningSession]) -> Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Average session length in minutes (0 when none).
    static func averageMinutes(_ sessions: [ListeningSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let total = totalSeconds(sessions)
        return Int((Double(total) / Double(sessions.count) / 60.0).rounded())
    }

    /// Minutes per calendar day for the most recent `days` days, oldest first.
    /// Always returns exactly `days` buckets so the chart axis is stable.
    static func nightlyMinutes(_ sessions: [ListeningSession],
                               days: Int = 14,
                               now: Date = Date(),
                               calendar: Calendar = .current) -> [NightlyTotal] {
        let span = max(1, days)
        guard let startDay = calendar.date(byAdding: .day, value: -(span - 1),
                                           to: calendar.startOfDay(for: now)) else {
            return []
        }

        // Bucket sessions by start-of-day.
        var byDay: [Date: Int] = [:]
        for s in sessions {
            let day = calendar.startOfDay(for: s.startedAt)
            guard day >= startDay else { continue }
            byDay[day, default: 0] += s.durationSeconds / 60
        }

        var result: [NightlyTotal] = []
        result.reserveCapacity(span)
        for offset in 0..<span {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            result.append(NightlyTotal(date: day, minutes: byDay[day] ?? 0))
        }
        return result
    }

    /// Most-used sounds across all sessions, descending by count.
    static func topSounds(_ sessions: [ListeningSession], limit: Int = 5) -> [SoundCount] {
        var counts: [SoundType: Int] = [:]
        for s in sessions {
            for sound in s.resolvedSounds {
                counts[sound, default: 0] += 1
            }
        }
        let sorted = counts
            .map { SoundCount(id: $0.key.rawValue, type: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.type.title < rhs.type.title : lhs.count > rhs.count
            }
        return Array(sorted.prefix(max(0, limit)))
    }

    /// The current streak of consecutive days (ending today or yesterday) that
    /// have at least one session.
    static func currentStreak(_ sessions: [ListeningSession],
                              now: Date = Date(),
                              calendar: Calendar = .current) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        let today = calendar.startOfDay(for: now)

        // Allow the streak to count if the most recent night was today or
        // yesterday (people sleep across midnight).
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
}
