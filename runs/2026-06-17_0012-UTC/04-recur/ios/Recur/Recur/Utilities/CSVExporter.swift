import Foundation

/// Builds a CSV export of all subscriptions (a Recur Pro feature).
enum CSVExporter {

    /// Returns a CSV string with a header row and one row per subscription.
    static func makeCSV(from subscriptions: [Subscription]) -> String {
        var rows: [String] = []
        rows.append([
            "Name", "Cost", "Currency", "Cycle", "First Billing",
            "Monthly Equivalent", "Annual Equivalent", "Category",
            "Payment Method", "Status", "Trial", "Trial End", "Notes"
        ].joined(separator: ","))

        for sub in subscriptions {
            let fields: [String] = [
                sub.name,
                String(format: "%.2f", sub.costAmount),
                sub.currencyCode,
                sub.cycle.label,
                DateText.medium(sub.firstBillingDate),
                MoneyFormatter.string(sub.monthlyEquivalent, code: sub.currencyCode),
                MoneyFormatter.string(sub.annualEquivalent, code: sub.currencyCode),
                sub.category.label,
                sub.paymentMethod,
                sub.isActive ? "Active" : "Cancelled",
                sub.isTrial ? "Yes" : "No",
                sub.trialEndDate.map { DateText.medium($0) } ?? "",
                sub.notes
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// Writes the CSV to a temporary file and returns its URL (nil on failure).
    static func writeTempFile(_ csv: String, filename: String = "Recur-Export.csv") -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(filename)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// CSV-escapes a field: wraps in quotes and doubles embedded quotes when needed.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
