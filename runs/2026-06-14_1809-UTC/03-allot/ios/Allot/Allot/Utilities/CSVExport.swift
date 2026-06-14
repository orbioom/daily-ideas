import Foundation

/// Builds a CSV string of all transactions for the Pro export feature.
enum CSVExport {

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Escape a field for CSV: wrap in quotes and double any inner quotes.
    private static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuoting ? "\"\(escaped)\"" : escaped
    }

    /// Produce a CSV with one row per transaction, newest first.
    static func build(transactions: [Transaction]) -> String {
        let header = ["Date", "Payee", "Amount", "Category", "Account", "Cleared", "Note"]
        var rows = [header.joined(separator: ",")]

        let sorted = transactions.sorted { $0.date > $1.date }
        for t in sorted {
            let fields = [
                dateFormatter.string(from: t.date),
                escape(t.payee),
                String(format: "%.2f", t.amount),
                escape(t.categoryRef?.name ?? ""),
                escape(t.accountRef?.name ?? ""),
                t.cleared ? "Yes" : "No",
                escape(t.note)
            ]
            rows.append(fields.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }
}
