import Foundation

/// Pure, deterministic logic over a challenge and its day logs. Kept free of
/// SwiftUI and of any persistence side effects so it is easy to reason about and
/// test. Views own the model context and create `DayLog`/`TaskTick` objects; the
/// engine only locates and evaluates them.
enum ChallengeEngine {

    // MARK: - Status types

    /// Per-day outcome within a run.
    enum DayStatus {
        case pending   // today, not yet all-satisfied
        case passed    // every required task satisfied
        case failed    // a past/today day that did not pass
        case future    // beyond today
    }

    /// Overall outcome of a run.
    enum OverallState {
        case notStarted
        case inProgress
        case completed
        case failed     // hard-mode run broken by a missed past day
    }

    // MARK: - Day math

    /// 1-based index of the current day, clamped to 1...durationDays.
    /// Returns 0 when the challenge has not been started.
    static func currentDayIndex(for challenge: Challenge,
                                now: Date = .now,
                                calendar: Calendar = .current) -> Int {
        guard let start = challenge.startDate else { return 0 }
        let startDay = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: now)
        let comps = calendar.dateComponents([.day], from: startDay, to: today)
        let delta = comps.day ?? 0
        let index = delta + 1
        return min(max(index, 1), max(challenge.durationDays, 1))
    }

    /// Locates the `DayLog` matching `dayIndex` for the given logs, if it exists.
    static func log(for dayIndex: Int, in logs: [DayLog]) -> DayLog? {
        logs.first { $0.dayIndex == dayIndex }
    }

    /// Locates today's `DayLog` for an active challenge, if one exists.
    static func todayLog(for challenge: Challenge,
                         now: Date = .now,
                         calendar: Calendar = .current) -> DayLog? {
        let idx = currentDayIndex(for: challenge, now: now, calendar: calendar)
        guard idx > 0 else { return nil }
        return log(for: idx, in: challenge.dayLogs)
    }

    // MARK: - Evaluation

    /// Whether a given log satisfies every required task of the challenge.
    static func isDayPassed(_ log: DayLog, requiredCount: Int) -> Bool {
        guard requiredCount > 0 else { return false }
        let satisfied = log.ticks.filter { $0.satisfied }.count
        return satisfied >= requiredCount
    }

    /// Status of a specific 1-based day index.
    static func status(of dayIndex: Int,
                       challenge: Challenge,
                       logs: [DayLog],
                       now: Date = .now,
                       calendar: Calendar = .current) -> DayStatus {
        let current = currentDayIndex(for: challenge, now: now, calendar: calendar)
        guard current > 0 else { return .future }

        let required = challenge.orderedTasks.count
        let passed = log(for: dayIndex, in: logs).map { isDayPassed($0, requiredCount: required) } ?? false

        if dayIndex < current {
            return passed ? .passed : .failed
        } else if dayIndex == current {
            return passed ? .passed : .pending
        } else {
            return .future
        }
    }

    // MARK: - Progress

    struct Progress {
        var dayIndex: Int
        var total: Int
        var passedDays: Int
        var percent: Double    // 0…1 of duration completed (passed days / total)
    }

    static func progress(for challenge: Challenge,
                         now: Date = .now,
                         calendar: Calendar = .current) -> Progress {
        let total = max(challenge.durationDays, 1)
        let idx = currentDayIndex(for: challenge, now: now, calendar: calendar)
        let logs = challenge.dayLogs
        let required = challenge.orderedTasks.count

        var passed = 0
        if idx > 0 {
            for day in 1...idx {
                if let l = log(for: day, in: logs), isDayPassed(l, requiredCount: required) {
                    passed += 1
                }
            }
        }
        let percent = Double(passed) / Double(total)
        return Progress(dayIndex: idx, total: total, passedDays: passed,
                        percent: min(max(percent, 0), 1))
    }

    /// Today's task completion for an active challenge.
    struct TodayProgress {
        var done: Int
        var required: Int
        var fraction: Double   // 0…1
    }

    static func todayProgress(for challenge: Challenge,
                              now: Date = .now,
                              calendar: Calendar = .current) -> TodayProgress {
        let required = challenge.orderedTasks.count
        guard required > 0 else { return TodayProgress(done: 0, required: 0, fraction: 0) }
        let log = todayLog(for: challenge, now: now, calendar: calendar)
        let done = log?.ticks.filter { $0.satisfied }.count ?? 0
        let clamped = min(done, required)
        return TodayProgress(done: clamped, required: required,
                             fraction: Double(clamped) / Double(required))
    }

    // MARK: - Overall state

    static func overallState(for challenge: Challenge,
                             now: Date = .now,
                             calendar: Calendar = .current) -> OverallState {
        guard challenge.startDate != nil else { return .notStarted }
        let idx = currentDayIndex(for: challenge, now: now, calendar: calendar)
        guard idx > 0 else { return .notStarted }

        let total = max(challenge.durationDays, 1)
        let prog = progress(for: challenge, now: now, calendar: calendar)

        if challenge.hardMode {
            // Any past day (strictly before today) that did not pass breaks the run.
            if idx > 1 {
                for day in 1..<idx {
                    if status(of: day, challenge: challenge, logs: challenge.dayLogs,
                              now: now, calendar: calendar) == .failed {
                        return .failed
                    }
                }
            }
        }

        if prog.passedDays >= total { return .completed }
        return .inProgress
    }

    // MARK: - Streaks

    /// Longest run of consecutive passed days across the whole duration.
    static func bestStreak(for challenge: Challenge,
                           now: Date = .now,
                           calendar: Calendar = .current) -> Int {
        let idx = currentDayIndex(for: challenge, now: now, calendar: calendar)
        guard idx > 0 else { return 0 }
        let required = challenge.orderedTasks.count
        let logs = challenge.dayLogs
        var best = 0
        var run = 0
        for day in 1...idx {
            let passed = log(for: day, in: logs).map { isDayPassed($0, requiredCount: required) } ?? false
            if passed {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        return best
    }

    /// Current run of consecutive passed days ending at the most recent passed day
    /// up to and including today.
    static func currentStreak(for challenge: Challenge,
                              now: Date = .now,
                              calendar: Calendar = .current) -> Int {
        let idx = currentDayIndex(for: challenge, now: now, calendar: calendar)
        guard idx > 0 else { return 0 }
        let required = challenge.orderedTasks.count
        let logs = challenge.dayLogs
        var run = 0
        var day = idx
        while day >= 1 {
            let passed = log(for: day, in: logs).map { isDayPassed($0, requiredCount: required) } ?? false
            if passed {
                run += 1
            } else if day == idx {
                // Today not yet passed is allowed mid-streak: keep walking back.
            } else {
                break
            }
            day -= 1
        }
        return run
    }
}
