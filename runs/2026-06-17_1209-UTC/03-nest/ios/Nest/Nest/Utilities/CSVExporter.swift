import Foundation

/// Builds a CSV of every goal's contributions for export/backup.
enum CSVExporter {

    static func makeCSV(goals: [Goal]) -> String {
        var rows = ["Goal,Category,Date,Type,Amount,Note"]
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]

        let sortedGoals = goals.sorted { $0.name < $1.name }
        for goal in sortedGoals {
            let sorted = goal.contributions.sorted { $0.date < $1.date }
            for c in sorted {
                let type = c.isWithdrawal ? "Withdrawal" : "Deposit"
                let amount = String(format: "%.2f", c.amount)
                let row = [
                    escape(goal.name),
                    escape(goal.category.title),
                    df.string(from: c.date),
                    type,
                    amount,
                    escape(c.note)
                ].joined(separator: ",")
                rows.append(row)
            }
        }
        return rows.joined(separator: "\n")
    }

    /// Write the CSV to a temporary file and return its URL, or nil on failure.
    static func writeTempFile(goals: [Goal]) -> URL? {
        let csv = makeCSV(goals: goals)
        let name = "Nest-Export-\(Int(Date.now.timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
