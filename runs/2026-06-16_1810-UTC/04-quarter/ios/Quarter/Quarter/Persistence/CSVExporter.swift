import Foundation

/// RFC-4180 compliant CSV export of the ledger. Pro-only at the call site.
enum CSVExporter {

    /// Escape a field per RFC 4180: wrap in quotes if it contains comma, quote,
    /// CR or LF; double any embedded quotes.
    static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"")
            || field.contains("\n") || field.contains("\r")
        if needsQuoting {
            let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return field
    }

    static func row(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    private static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Build a combined income + expense CSV. Lines joined with CRLF per RFC 4180.
    static func ledgerCSV(income: [IncomeEntry], expenses: [ExpenseEntry]) -> String {
        var lines: [String] = []
        lines.append(row(["Type", "Date", "Label", "Category/Source", "Business", "Amount"]))

        for e in income.sorted(by: { $0.date < $1.date }) {
            lines.append(row([
                "Income",
                isoDate.string(from: e.date),
                e.label,
                e.source,
                e.isBusiness ? "Yes" : "No",
                String(format: "%.2f", e.amount)
            ]))
        }
        for e in expenses.sorted(by: { $0.date < $1.date }) {
            lines.append(row([
                "Expense",
                isoDate.string(from: e.date),
                e.label,
                e.category,
                "Yes",
                String(format: "%.2f", e.amount)
            ]))
        }
        return lines.joined(separator: "\r\n")
    }

    /// Write the CSV to a temporary file and return its URL (for share sheet).
    static func writeTemporaryFile(_ csv: String, filename: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(filename)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
