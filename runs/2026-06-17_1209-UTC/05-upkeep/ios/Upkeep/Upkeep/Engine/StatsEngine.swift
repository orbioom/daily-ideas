import Foundation

struct MonthCount: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let count: Int
}

struct SystemCount: Identifiable {
    let id = UUID()
    let systemName: String
    let count: Int
}

struct StatsResult {
    var totalCompletions: Int = 0
    var activeTaskCount: Int = 0
    var onTimeRate: Double = 0        // 0...1
    var currentStreakWeeks: Int = 0
    var completionsByMonth: [MonthCount] = []
    var completionsBySystem: [SystemCount] = []

    var isEmpty: Bool { totalCompletions == 0 }
}

/// Pure statistics over completion logs.
enum StatsEngine {

    static func compute(tasks: [MaintenanceTask],
                        hemisphere: Hemisphere,
                        monthsBack: Int = 12,
                        now: Date = Date(),
                        calendar: Calendar = .current) -> StatsResult {
        var result = StatsResult()
        result.activeTaskCount = tasks.filter { $0.isActive }.count

        // Flatten all (task, log) pairs.
        var allLogs: [(task: MaintenanceTask, log: CompletionLog)] = []
        for task in tasks {
            for log in task.logs { allLogs.append((task, log)) }
        }
        result.totalCompletions = allLogs.count

        // On-time rate: a log counts as on-time if it landed on/before that
        // task's scheduled due date relative to the PREVIOUS completion.
        if !allLogs.isEmpty {
            var onTime = 0
            for task in tasks {
                let sorted = task.logs.sorted { $0.date < $1.date }
                for (idx, log) in sorted.enumerated() {
                    let prior = idx > 0 ? sorted[idx - 1].date : task.createdAt
                    if let due = dueDate(forCadenceOf: task,
                                         from: prior,
                                         hemisphere: hemisphere,
                                         calendar: calendar) {
                        if calendar.startOfDay(for: log.date) <= calendar.startOfDay(for: due) {
                            onTime += 1
                        }
                    } else {
                        onTime += 1 // unscheduled seasonal: don't penalize
                    }
                }
            }
            result.onTimeRate = Double(onTime) / Double(allLogs.count)
        }

        // Completions by month (last `monthsBack` months).
        let safeMonths = max(1, monthsBack)
        var monthBuckets: [(start: Date, label: String)] = []
        let df = DateFormatter()
        df.dateFormat = "MMM"
        let startOfThisMonth = startOfMonth(now, calendar: calendar)
        for i in stride(from: safeMonths - 1, through: 0, by: -1) {
            if let start = calendar.date(byAdding: .month, value: -i, to: startOfThisMonth) {
                monthBuckets.append((start, df.string(from: start)))
            }
        }
        result.completionsByMonth = monthBuckets.map { bucket in
            let count = allLogs.filter {
                startOfMonth($0.log.date, calendar: calendar) == bucket.start
            }.count
            return MonthCount(monthStart: bucket.start, label: bucket.label, count: count)
        }

        // Completions by system.
        var systemMap: [String: Int] = [:]
        for entry in allLogs { systemMap[entry.task.systemName, default: 0] += 1 }
        result.completionsBySystem = systemMap
            .map { SystemCount(systemName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // Current streak: consecutive recent weeks (ending this week) with ≥1 completion.
        result.currentStreakWeeks = weekStreak(logs: allLogs.map { $0.log },
                                               now: now,
                                               calendar: calendar)
        return result
    }

    /// Next due date for a task's cadence measured from an arbitrary anchor.
    private static func dueDate(forCadenceOf task: MaintenanceTask,
                                from anchor: Date,
                                hemisphere: Hemisphere,
                                calendar: Calendar) -> Date? {
        switch task.cadenceType {
        case .everyNDays:
            return calendar.date(byAdding: .day, value: max(1, task.intervalCount), to: anchor)
        case .everyNWeeks:
            return calendar.date(byAdding: .day, value: max(1, task.intervalCount) * 7, to: anchor)
        case .everyNMonths:
            return calendar.date(byAdding: .month, value: max(1, task.intervalCount), to: anchor)
        case .everyNYears:
            return calendar.date(byAdding: .year, value: max(1, task.intervalCount), to: anchor)
        case .seasonal:
            guard let season = task.season else { return nil }
            return ScheduleEngine.nextSeasonStart(season: season,
                                                  after: anchor,
                                                  hemisphere: hemisphere,
                                                  calendar: calendar)
        }
    }

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    private static func weekStreak(logs: [CompletionLog], now: Date, calendar: Calendar) -> Int {
        guard !logs.isEmpty else { return 0 }
        let weeksWithWork: Set<Date> = Set(logs.compactMap { log in
            calendar.dateInterval(of: .weekOfYear, for: log.date)?.start
        })
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }

        var streak = 0
        var cursor = thisWeek
        // Walk back week by week while each week had at least one completion.
        while weeksWithWork.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
