import Foundation

struct SystemSpend: Identifiable {
    let id = UUID()
    let systemName: String
    let total: Double
}

struct YearSpend: Identifiable {
    let id = UUID()
    let year: Int
    let total: Double
}

struct CostSummary {
    var totalSpentAllTime: Double = 0
    var spentThisYear: Double = 0
    var byYear: [YearSpend] = []
    var bySystem: [SystemSpend] = []
    var upcomingEstimated: Double = 0     // estimated cost of due-soon tasks
    var annualizedEstimate: Double = 0    // estimated yearly maintenance cost

    var isEmpty: Bool { totalSpentAllTime == 0 && annualizedEstimate == 0 }
}

/// Pure cost aggregation. Money kept in Double, presented via Decimal elsewhere.
enum CostEngine {

    static func summarize(tasks: [MaintenanceTask],
                          hemisphere: Hemisphere,
                          dueSoonDays: Int,
                          now: Date = Date(),
                          calendar: Calendar = .current) -> CostSummary {
        var summary = CostSummary()
        let thisYear = calendar.component(.year, from: now)

        var yearMap: [Int: Double] = [:]
        var systemMap: [String: Double] = [:]

        for task in tasks {
            for log in task.logs {
                guard let cost = log.costActual, cost > 0 else { continue }
                summary.totalSpentAllTime += cost
                let y = calendar.component(.year, from: log.date)
                yearMap[y, default: 0] += cost
                if y == thisYear { summary.spentThisYear += cost }
                systemMap[task.systemName, default: 0] += cost
            }
        }

        summary.byYear = yearMap
            .map { YearSpend(year: $0.key, total: round2($0.value)) }
            .sorted { $0.year < $1.year }

        summary.bySystem = systemMap
            .map { SystemSpend(systemName: $0.key, total: round2($0.value)) }
            .sorted { $0.total > $1.total }

        // Upcoming = estimated cost of active tasks due now / soon.
        var upcoming = 0.0
        var annual = 0.0
        for task in tasks where task.isActive {
            if let est = task.estimatedCost, est > 0 {
                let bucket = ScheduleEngine.bucket(for: task,
                                                   hemisphere: hemisphere,
                                                   dueSoonDays: dueSoonDays,
                                                   now: now,
                                                   calendar: calendar)
                if bucket == .overdue || bucket == .dueToday || bucket == .dueSoon {
                    upcoming += est
                }
                // Annualize: how many times per year does this occur × est cost.
                let perYear = occurrencesPerYear(for: task)
                annual += est * perYear
            }
        }

        summary.upcomingEstimated = round2(upcoming)
        summary.annualizedEstimate = round2(annual)
        summary.totalSpentAllTime = round2(summary.totalSpentAllTime)
        summary.spentThisYear = round2(summary.spentThisYear)
        return summary
    }

    /// Approximate number of times a task recurs per year.
    static func occurrencesPerYear(for task: MaintenanceTask) -> Double {
        let interval = Double(ScheduleEngine.intervalDays(for: task))
        guard interval > 0 else { return 0 }
        return 365.0 / interval
    }

    private static func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
