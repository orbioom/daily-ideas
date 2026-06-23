import Foundation

/// Pure aggregation used by the Due dashboard. Kept separate from the view so
/// the bucketing math can be computed off the main actor and unit-reasoned.
struct DashboardSummary {
    var health: Int = 100
    var overdue: [MaintenanceTask] = []
    var dueToday: [MaintenanceTask] = []
    var dueSoon: [MaintenanceTask] = []
    var upcoming: [MaintenanceTask] = []
    var completedThisMonth: Int = 0
    var spentThisMonth: Double = 0

    var totalActionable: Int { overdue.count + dueToday.count }
    var isAllClear: Bool { overdue.isEmpty && dueToday.isEmpty && dueSoon.isEmpty }
}

enum DashboardBuilder {
    static func build(from tasks: [MaintenanceTask],
                      dueSoonWindow: Int,
                      today: Date = .now,
                      calendar: Calendar = .current) -> DashboardSummary {
        var summary = DashboardSummary()
        summary.health = ScheduleEngine.homeHealth(tasks: tasks, today: today, dueSoonWindow: dueSoonWindow)

        for task in tasks {
            switch ScheduleEngine.status(for: task, today: today, dueSoonWindow: dueSoonWindow, calendar: calendar) {
            case .overdue:  summary.overdue.append(task)
            case .dueToday: summary.dueToday.append(task)
            case .dueSoon:  summary.dueSoon.append(task)
            case .upcoming: summary.upcoming.append(task)
            case .inactive: break
            }
        }
        summary.overdue.sort { $0.nextDue < $1.nextDue }
        summary.dueToday.sort { $0.title < $1.title }
        summary.dueSoon.sort { $0.nextDue < $1.nextDue }
        summary.upcoming.sort { $0.nextDue < $1.nextDue }

        // Completion / spend this calendar month from service records.
        let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        for task in tasks {
            for rec in task.records where rec.completedDate >= monthStart && rec.completedDate <= today {
                summary.completedThisMonth += 1
                summary.spentThisMonth += rec.cost
            }
        }
        return summary
    }
}
