import Foundation

/// Pure analytics over completed workout sessions. All inputs snapshotted by the caller.
enum StatsEngine {

    // MARK: Output value types

    struct E1RMPoint: Identifiable {
        let id = UUID()
        let date: Date
        let e1rmKg: Double
    }

    struct VolumeByGroup: Identifiable {
        let id = UUID()
        let group: MuscleGroup
        let volumeKg: Double
    }

    struct WeeklyVolume: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volumeKg: Double
    }

    struct LiftPR: Identifiable {
        let id = UUID()
        let liftName: String
        let bestE1RMKg: Double
        let date: Date
    }

    struct Summary {
        let sessionCount: Int
        let totalVolumeKg: Double
        let currentStreakWeeks: Int
        let distinctLifts: Int
    }

    // MARK: Inputs

    /// Caller maps SwiftData sessions into these plain snapshots on the main actor.
    struct SessionSnapshot {
        let date: Date
        let lifts: [LiftSnapshot]
    }

    struct LiftSnapshot {
        let name: String
        let group: MuscleGroup
        /// Completed working sets only.
        let sets: [(weightKg: Double, reps: Int)]
    }

    // MARK: Computations

    /// e1RM over time for one lift (one point per session that included it), oldest first.
    static func e1rmSeries(liftName: String, sessions: [SessionSnapshot]) -> [E1RMPoint] {
        var points: [E1RMPoint] = []
        for s in sessions.sorted(by: { $0.date < $1.date }) {
            guard let lift = s.lifts.first(where: { $0.name == liftName }) else { continue }
            let best = OneRepMax.best(from: lift.sets)
            guard best > 0 else { continue }
            points.append(E1RMPoint(date: s.date, e1rmKg: best))
        }
        return points
    }

    /// Total volume grouped by muscle group across all sessions.
    static func volumeByGroup(sessions: [SessionSnapshot]) -> [VolumeByGroup] {
        var totals: [MuscleGroup: Double] = [:]
        for s in sessions {
            for lift in s.lifts {
                let v = lift.sets.reduce(0) { $0 + $1.weightKg * Double($1.reps) }
                totals[lift.group, default: 0] += v
            }
        }
        return MuscleGroup.allCases
            .compactMap { g in totals[g].map { VolumeByGroup(group: g, volumeKg: $0) } }
            .filter { $0.volumeKg > 0 }
            .sorted { $0.volumeKg > $1.volumeKg }
    }

    /// Weekly total volume (Monday-anchored), oldest first.
    static func weeklyVolume(sessions: [SessionSnapshot], calendar: Calendar = .current) -> [WeeklyVolume] {
        var buckets: [Date: Double] = [:]
        for s in sessions {
            guard let week = weekStart(for: s.date, calendar: calendar) else { continue }
            let v = s.lifts.reduce(0) { acc, lift in
                acc + lift.sets.reduce(0) { $0 + $1.weightKg * Double($1.reps) }
            }
            buckets[week, default: 0] += v
        }
        return buckets
            .map { WeeklyVolume(weekStart: $0.key, volumeKg: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    /// Best e1RM per lift, sorted by heaviest.
    static func personalRecords(sessions: [SessionSnapshot]) -> [LiftPR] {
        var best: [String: (kg: Double, date: Date)] = [:]
        for s in sessions {
            for lift in s.lifts {
                let e = OneRepMax.best(from: lift.sets)
                guard e > 0 else { continue }
                if let existing = best[lift.name] {
                    if e > existing.kg { best[lift.name] = (e, s.date) }
                } else {
                    best[lift.name] = (e, s.date)
                }
            }
        }
        return best
            .map { LiftPR(liftName: $0.key, bestE1RMKg: $0.value.kg, date: $0.value.date) }
            .sorted { $0.bestE1RMKg > $1.bestE1RMKg }
    }

    /// Headline summary numbers.
    static func summary(sessions: [SessionSnapshot], calendar: Calendar = .current) -> Summary {
        let totalVolume = sessions.reduce(0.0) { acc, s in
            acc + s.lifts.reduce(0) { $0 + $1.sets.reduce(0) { $0 + $1.weightKg * Double($1.reps) } }
        }
        let lifts = Set(sessions.flatMap { $0.lifts.map { $0.name } })
        return Summary(sessionCount: sessions.count,
                       totalVolumeKg: totalVolume,
                       currentStreakWeeks: currentStreakWeeks(sessions: sessions, calendar: calendar),
                       distinctLifts: lifts.count)
    }

    /// Names of all distinct lifts that appear, alphabetical.
    static func liftNames(sessions: [SessionSnapshot]) -> [String] {
        Array(Set(sessions.flatMap { $0.lifts.map { $0.name } }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // MARK: Helpers

    /// Consecutive weeks (ending this week or last) that contain at least one session.
    static func currentStreakWeeks(sessions: [SessionSnapshot], calendar: Calendar = .current) -> Int {
        let weeks = Set(sessions.compactMap { weekStart(for: $0.date, calendar: calendar) })
        guard !weeks.isEmpty else { return 0 }
        guard let thisWeek = weekStart(for: Date(), calendar: calendar) else { return 0 }
        let weekSeconds: TimeInterval = 7 * 24 * 60 * 60

        // Allow the streak to "start" at this week or last week (in case today is early in the week).
        var anchor = thisWeek
        if !weeks.contains(anchor) {
            anchor = anchor.addingTimeInterval(-weekSeconds)
            guard weeks.contains(anchor) else { return 0 }
        }

        var streak = 0
        var cursor = anchor
        while weeks.contains(cursor) {
            streak += 1
            cursor = cursor.addingTimeInterval(-weekSeconds)
            // Re-anchor to the calendar week boundary to avoid DST drift.
            if let realigned = weekStart(for: cursor, calendar: calendar) {
                cursor = realigned
            }
        }
        return streak
    }

    private static func weekStart(for date: Date, calendar: Calendar) -> Date? {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start
    }
}
