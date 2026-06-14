import Foundation

/// One day's bucket in the runs heatmap.
struct HeatCell: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

/// One week's run count for the weekly chart.
struct WeekBucket: Identifiable {
    let id = UUID()
    let weekStart: Date
    let runs: Int
    let minutes: Int
}

/// Per-routine completion summary.
struct RoutineCompletion: Identifiable {
    let id: UUID
    let name: String
    let runs: Int
    let completed: Int

    var rate: Double {
        guard runs > 0 else { return 0 }
        return Double(completed) / Double(runs)
    }
}

/// The fully computed Progress snapshot.
struct ProgressStats {
    var totalRuns: Int = 0
    var completedRuns: Int = 0
    var totalMinutes: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var heat: [HeatCell] = []
    var weeks: [WeekBucket] = []
    var perRoutine: [RoutineCompletion] = []
    var bestTimeOfDay: TimeOfDay?

    var isEmpty: Bool { totalRuns == 0 }

    var completionRate: Double {
        guard totalRuns > 0 else { return 0 }
        return Double(completedRuns) / Double(totalRuns)
    }
}

/// Today's status of a single routine.
enum TodayStatus {
    case done
    case notYet
}

/// Pure stats engine over `RoutineRun` records. No SwiftData fetches inside.
enum RoutineEngine {

    /// A run counts as "completed" when its completion fraction meets the threshold.
    static func isCompleted(_ run: RoutineRun, threshold: CompletionThreshold) -> Bool {
        run.completionFraction >= threshold.minFraction - 0.0001
    }

    /// Today's status for one routine: done if any qualifying run happened today.
    static func todayStatus(routine: Routine,
                            runs: [RoutineRun],
                            threshold: CompletionThreshold,
                            calendar: Calendar = .current,
                            now: Date = Date()) -> TodayStatus {
        let didRun = runs.contains { run in
            guard run.routineRef?.id == routine.id else { return false }
            guard isCompleted(run, threshold: threshold) else { return false }
            return calendar.isDate(run.date, inSameDayAs: now)
        }
        return didRun ? .done : .notYet
    }

    /// Overall streak: consecutive days (ending today or yesterday) with >=1 completed run.
    static func overallStreak(runs: [RoutineRun],
                             threshold: CompletionThreshold,
                             calendar: Calendar = .current,
                             now: Date = Date()) -> Int {
        let days = completedDaySet(runs: runs, threshold: threshold, calendar: calendar)
        return streakLength(days: days, calendar: calendar, now: now)
    }

    /// Per-routine streak (consecutive days with >=1 completed run of that routine).
    static func streak(for routine: Routine,
                       runs: [RoutineRun],
                       threshold: CompletionThreshold,
                       calendar: Calendar = .current,
                       now: Date = Date()) -> Int {
        let filtered = runs.filter { $0.routineRef?.id == routine.id }
        let days = completedDaySet(runs: filtered, threshold: threshold, calendar: calendar)
        return streakLength(days: days, calendar: calendar, now: now)
    }

    /// Longest historical streak across all completed-run days.
    static func longestStreak(runs: [RoutineRun],
                              threshold: CompletionThreshold,
                              calendar: Calendar = .current) -> Int {
        let days = completedDaySet(runs: runs, threshold: threshold, calendar: calendar)
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            if let next = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               calendar.isDate(next, inSameDayAs: sorted[i]) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
        }
        return best
    }

    /// Full Progress snapshot over all runs and known routines.
    static func compute(runs: [RoutineRun],
                        routines: [Routine],
                        settings calendarFirstWeekday: Int,
                        threshold: CompletionThreshold,
                        now: Date = Date()) -> ProgressStats {
        var cal = Calendar.current
        cal.firstWeekday = calendarFirstWeekday

        var stats = ProgressStats()
        stats.totalRuns = runs.count
        stats.completedRuns = runs.filter { isCompleted($0, threshold: threshold) }.count
        stats.totalMinutes = runs.reduce(0) { $0 + $1.durationSec } / 60
        stats.currentStreak = overallStreak(runs: runs, threshold: threshold, calendar: cal, now: now)
        stats.longestStreak = longestStreak(runs: runs, threshold: threshold, calendar: cal)
        stats.heat = heatmap(runs: runs, calendar: cal, now: now, days: 35)
        stats.weeks = weeklyBuckets(runs: runs, calendar: cal, now: now, weeks: 8)
        stats.perRoutine = perRoutine(runs: runs, routines: routines, threshold: threshold)
        stats.bestTimeOfDay = bestTimeOfDay(runs: runs)
        return stats
    }

    // MARK: - Heatmap

    /// Run counts per day for the last `days` days (oldest first).
    static func heatmap(runs: [RoutineRun],
                        calendar: Calendar = .current,
                        now: Date = Date(),
                        days: Int) -> [HeatCell] {
        guard days > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        var counts: [Date: Int] = [:]
        for run in runs {
            let day = calendar.startOfDay(for: run.date)
            counts[day, default: 0] += 1
        }
        var cells: [HeatCell] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            cells.append(HeatCell(date: day, count: counts[day] ?? 0))
        }
        return cells
    }

    // MARK: - Weekly buckets

    static func weeklyBuckets(runs: [RoutineRun],
                              calendar: Calendar = .current,
                              now: Date = Date(),
                              weeks: Int) -> [WeekBucket] {
        guard weeks > 0 else { return [] }
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }

        var runCounts: [Date: Int] = [:]
        var minuteSums: [Date: Int] = [:]
        for run in runs {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: run.date)?.start else { continue }
            runCounts[start, default: 0] += 1
            minuteSums[start, default: 0] += run.durationSec / 60
        }

        var buckets: [WeekBucket] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { continue }
            buckets.append(WeekBucket(weekStart: weekStart,
                                      runs: runCounts[weekStart] ?? 0,
                                      minutes: minuteSums[weekStart] ?? 0))
        }
        return buckets
    }

    // MARK: - Per-routine completion

    static func perRoutine(runs: [RoutineRun],
                           routines: [Routine],
                           threshold: CompletionThreshold) -> [RoutineCompletion] {
        routines.compactMap { routine in
            let mine = runs.filter { $0.routineRef?.id == routine.id }
            guard !mine.isEmpty else { return nil }
            let completed = mine.filter { isCompleted($0, threshold: threshold) }.count
            return RoutineCompletion(id: routine.id,
                                     name: routine.name,
                                     runs: mine.count,
                                     completed: completed)
        }
        .sorted { $0.runs > $1.runs }
    }

    // MARK: - Best time of day

    static func bestTimeOfDay(runs: [RoutineRun]) -> TimeOfDay? {
        guard !runs.isEmpty else { return nil }
        var tally: [TimeOfDay: Int] = [:]
        for run in runs {
            if let tod = run.routineRef?.timeOfDay {
                tally[tod, default: 0] += 1
            }
        }
        return tally.max { lhs, rhs in lhs.value < rhs.value }?.key
    }

    // MARK: - Helpers

    /// Distinct days (start-of-day) that had at least one completed run.
    private static func completedDaySet(runs: [RoutineRun],
                                        threshold: CompletionThreshold,
                                        calendar: Calendar) -> Set<Date> {
        var days: Set<Date> = []
        for run in runs where isCompleted(run, threshold: threshold) {
            days.insert(calendar.startOfDay(for: run.date))
        }
        return days
    }

    /// Consecutive-day streak ending today (or yesterday, so a missed "today" is forgiven).
    private static func streakLength(days: Set<Date>, calendar: Calendar, now: Date) -> Int {
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}
