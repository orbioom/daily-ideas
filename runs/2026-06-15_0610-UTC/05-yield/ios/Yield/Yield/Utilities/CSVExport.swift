import Foundation

/// Builds a CSV string from holdings for the Pro export feature. Pure string work — the
/// caller shares it via a share sheet. Values are quoted/escaped defensively.
enum CSVExport {

    static func holdingsCSV(_ holdings: [Holding], currencyCode: String) -> String {
        var rows: [String] = []
        rows.append([
            "Ticker", "Name", "Shares", "AvgCostPerShare", "AnnualDividendPerShare",
            "CurrentPrice", "Frequency", "PayCycle", "PayDay", "Sector", "Account",
            "ProjectedAnnualIncome", "YieldOnCost"
        ].joined(separator: ","))

        for h in holdings {
            let annual = IncomeEngine.annualIncome(for: h)
            let yoc = IncomeEngine.yieldOnCost(for: h)
            let fields: [String] = [
                h.ticker,
                h.name,
                decimalString(h.shares),
                decimalString(h.avgCostPerShare),
                decimalString(h.annualDividendPerShare),
                h.currentPrice.map { decimalString($0) } ?? "",
                h.frequency.label,
                h.payCycle.label(for: h.frequency),
                "\(h.payDayOfMonth)",
                h.sector.label,
                h.account ?? "",
                decimalString(annual),
                yoc.map { String(format: "%.4f", $0) } ?? ""
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    /// Escape a field for CSV: wrap in quotes and double any embedded quotes if needed.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// Write the CSV to a temporary file and return its URL for sharing.
    static func writeTempFile(_ csv: String, filename: String = "Yield-Portfolio.csv") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
