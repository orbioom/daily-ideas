import Foundation

/// Builds a CSV export of tasks and their completion logs.
enum ExportBuilder {

    /// One row per completion log, plus a row for tasks that have never been completed.
    static func csv(for tasks: [MaintenanceTask],
                    hemisphere: Hemisphere) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var lines: [String] = []
        lines.append("Task,System,Cadence,Priority,LastDone,NextDue,CompletionDate,CostActual,MinutesSpent,Note")

        for task in tasks.sorted(by: { $0.systemName < $1.systemName }) {
            let cadence = task.cadenceType.describe(interval: task.intervalCount, season: task.season)
            let nextDue = ScheduleEngine.nextDue(for: task, hemisphere: hemisphere)
            let nextDueStr = nextDue.map { formatter.string(from: $0) } ?? ""
            let lastDoneStr = task.lastDone.map { formatter.string(from: $0) } ?? ""

            let sortedLogs = task.logs.sorted { $0.date < $1.date }
            if sortedLogs.isEmpty {
                lines.append(row([task.title, task.systemName, cadence, task.priorityLabel,
                                  lastDoneStr, nextDueStr, "", "", "", ""]))
            } else {
                for log in sortedLogs {
                    let cost = log.costActual.map { String(format: "%.2f", $0) } ?? ""
                    let minutes = log.minutesSpent.map { String($0) } ?? ""
                    lines.append(row([task.title, task.systemName, cadence, task.priorityLabel,
                                      lastDoneStr, nextDueStr,
                                      formatter.string(from: log.date), cost, minutes, log.note]))
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Escape a CSV field and join a row.
    private static func row(_ fields: [String]) -> String {
        fields.map { escape($0) }.joined(separator: ",")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
