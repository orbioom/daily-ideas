import Foundation

/// Pure, deterministic analytics over sessions and their attempts. No SwiftUI,
/// no SwiftData fetching here — callers pass in the already-loaded records so this
/// stays testable and never crashes on user data.
enum Analytics {

    // MARK: - Send pyramid

    /// One rung of a send pyramid: a canonical grade index and the count of sends.
    struct PyramidRung: Identifiable {
        let index: Int
        let count: Int
        var id: Int { index }
    }

    /// Build a send pyramid for one grade family: counts of sends per canonical grade,
    /// highest grade first. Only `isSend` attempts count.
    static func sendPyramid(attempts: [Attempt], family: GradeFamily) -> [PyramidRung] {
        var counts: [Int: Int] = [:]
        for attempt in attempts where attempt.outcome.isSend && attempt.gradeFamily == family {
            guard GradeScale.isValid(index: attempt.gradeIndex, family: family) else { continue }
            counts[attempt.gradeIndex, default: 0] += 1
        }
        return counts
            .map { PyramidRung(index: $0.key, count: $0.value) }
            .sorted { $0.index > $1.index }
    }

    // MARK: - Rates

    /// Flash/onsight rate: of all sends, the fraction that were first-go clean.
    /// Returns nil when there are no sends (avoids division by zero).
    static func flashRate(attempts: [Attempt]) -> Double? {
        let sends = attempts.filter { $0.outcome.isSend }
        guard !sends.isEmpty else { return nil }
        let firstGo = sends.filter { $0.outcome.isFirstGo }.count
        return Double(firstGo) / Double(sends.count)
    }

    /// Overall send rate: of all attempts, the fraction that were sends.
    static func sendRate(attempts: [Attempt]) -> Double? {
        guard !attempts.isEmpty else { return nil }
        let sends = attempts.filter { $0.outcome.isSend }.count
        return Double(sends) / Double(attempts.count)
    }

    // MARK: - Maxima

    /// Hardest send for a family, as a canonical index. Nil when no sends exist.
    static func maxSendIndex(attempts: [Attempt], family: GradeFamily) -> Int? {
        attempts
            .filter { $0.outcome.isSend && $0.gradeFamily == family }
            .map(\.gradeIndex)
            .filter { GradeScale.isValid(index: $0, family: family) }
            .max()
    }

    /// Hardest grade attempted (sent or not) for a family. Nil when none exist.
    static func maxAttemptedIndex(attempts: [Attempt], family: GradeFamily) -> Int? {
        attempts
            .filter { $0.gradeFamily == family }
            .map(\.gradeIndex)
            .filter { GradeScale.isValid(index: $0, family: family) }
            .max()
    }

    // MARK: - Monthly progression

    /// One month of progression: the hardest send that month for a family.
    struct MonthPoint: Identifiable {
        /// First instant of the month (used for sorting + axis).
        let month: Date
        /// Hardest send index that month, or nil if no send (shown as a gap).
        let hardestIndex: Int?
        var id: Date { month }
    }

    /// Hardest send per calendar month for a family, ascending by month. Includes
    /// only months that had at least one logged attempt of that family so the chart
    /// reflects real activity. Months with attempts but no sends carry `nil`.
    static func monthlyProgression(sessions: [Session],
                                   family: GradeFamily,
                                   calendar: Calendar = .current) -> [MonthPoint] {
        var byMonth: [Date: [Attempt]] = [:]
        for session in sessions {
            let monthStart = startOfMonth(session.date, calendar: calendar)
            for attempt in session.attempts where attempt.gradeFamily == family {
                byMonth[monthStart, default: []].append(attempt)
            }
        }
        return byMonth
            .map { (month, attempts) in
                let hardest = attempts
                    .filter { $0.outcome.isSend }
                    .map(\.gradeIndex)
                    .filter { GradeScale.isValid(index: $0, family: family) }
                    .max()
                return MonthPoint(month: month, hardestIndex: hardest)
            }
            .sorted { $0.month < $1.month }
    }

    // MARK: - Volume over time

    /// One day (or session) of volume: attempt count.
    struct VolumePoint: Identifiable {
        let date: Date
        let attempts: Int
        let sends: Int
        var id: Date { date }
    }

    /// Attempt + send volume per session, ascending by date.
    static func volume(sessions: [Session]) -> [VolumePoint] {
        sessions
            .map { VolumePoint(date: $0.date, attempts: $0.attemptCount, sends: $0.sendCount) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Totals

    /// Lightweight summary used on dashboards.
    struct Summary {
        let sessionCount: Int
        let attemptCount: Int
        let sendCount: Int
        let projectsInProgress: Int
        let totalMinutes: Int
    }

    static func summary(sessions: [Session], climbs: [Climb]) -> Summary {
        let attempts = sessions.flatMap(\.attempts)
        return Summary(
            sessionCount: sessions.count,
            attemptCount: attempts.count,
            sendCount: attempts.filter { $0.outcome.isSend }.count,
            projectsInProgress: climbs.filter { $0.isProject && !$0.isSent }.count,
            totalMinutes: sessions.reduce(0) { $0 + max($1.durationMinutes, 0) }
        )
    }

    // MARK: - Helpers

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }
}
