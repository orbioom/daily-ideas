import Foundation

/// Pure mobility math: streaks, weekly load, area balance, session expansion.
enum MobilityEngine {

    // MARK: - Session expansion

    /// One concrete phase the player counts down. A both-sides stretch becomes
    /// two phases (one per side).
    struct Phase: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        let area: BodyArea
        let seconds: Int
        let sideLabel: String?   // "Left" / "Right" or nil
    }

    static func phases(for routine: Routine) -> [Phase] {
        var out: [Phase] = []
        for step in routine.orderedSteps {
            guard let s = step.stretch else { continue }
            if s.bothSides {
                out.append(Phase(name: s.name, detail: s.detail, area: s.area,
                                 seconds: step.seconds, sideLabel: "Left side"))
                out.append(Phase(name: s.name, detail: s.detail, area: s.area,
                                 seconds: step.seconds, sideLabel: "Right side"))
            } else {
                out.append(Phase(name: s.name, detail: s.detail, area: s.area,
                                 seconds: step.seconds, sideLabel: nil))
            }
        }
        return out
    }

    // MARK: - Streaks

    /// Consecutive days (ending today or yesterday) with at least one session.
    static func currentStreak(_ logs: [SessionLog], now: Date = .now,
                              calendar: Calendar = .current) -> Int {
        let days = Set(logs.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        // Allow the streak to "hold" if today not done yet but yesterday was.
        var anchor = today
        if !days.contains(today) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(y) else { return 0 }
            anchor = y
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

    static func longestStreak(_ logs: [SessionLog], calendar: Calendar = .current) -> Int {
        let days = logs.map { calendar.startOfDay(for: $0.date) }.sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1, run = 1
        for i in 1..<days.count {
            if days[i] == days[i-1] { continue }
            if let next = calendar.date(byAdding: .day, value: 1, to: days[i-1]), next == days[i] {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: - Daily totals

    static func secondsToday(_ logs: [SessionLog], now: Date = .now,
                             calendar: Calendar = .current) -> Int {
        logs.filter { calendar.isDate($0.date, inSameDayAs: now) }
            .reduce(0) { $0 + $1.seconds }
    }

    struct DayMinutes: Identifiable {
        let id = UUID()
        let day: Date
        let minutes: Double
    }

    /// Minutes per day for the trailing `days` window (oldest → newest).
    static func dailyMinutes(_ logs: [SessionLog], days: Int = 14,
                             now: Date = .now, calendar: Calendar = .current) -> [DayMinutes] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let secs = logs.filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.seconds }
            return DayMinutes(day: day, minutes: Double(secs) / 60)
        }
    }

    // MARK: - Area balance

    struct AreaCount: Identifiable {
        var id: String { area.rawValue }
        let area: BodyArea
        let count: Int
    }

    /// How often each body area appeared across the trailing window of sessions.
    static func areaBalance(_ logs: [SessionLog], lastN: Int = 30) -> [AreaCount] {
        var totals: [BodyArea: Int] = [:]
        for log in logs.prefix(lastN) {
            for a in log.areas { totals[a, default: 0] += 1 }
        }
        return totals.map { AreaCount(area: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Aggregates

    static func totalMinutes(_ logs: [SessionLog]) -> Int {
        Int((Double(logs.reduce(0) { $0 + $1.seconds }) / 60).rounded())
    }

    static func averageFeeling(_ logs: [SessionLog]) -> Double? {
        let rated = logs.filter { $0.feeling > 0 }
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0) { $0 + $1.feeling }) / Double(rated.count)
    }

    static func secondsString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }
}
