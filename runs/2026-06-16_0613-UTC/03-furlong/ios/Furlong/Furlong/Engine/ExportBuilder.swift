import Foundation

/// Builds RFC-4180-escaped CSV and human-readable plain-text exports.
enum ExportBuilder {

    /// Escape a single CSV field per RFC 4180: wrap in quotes if it contains
    /// a comma, quote, CR or LF; double any embedded quotes.
    static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(",") || raw.contains("\"")
            || raw.contains("\n") || raw.contains("\r")
        if needsQuoting {
            let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return raw
    }

    private static func row(_ fields: [String]) -> String {
        fields.map(csvField).joined(separator: ",")
    }

    private static func decimalString(_ value: Decimal) -> String {
        let rounded = DeductionEngine.cents(value)
        return NSDecimalNumber(decimal: rounded).stringValue
    }

    // MARK: - Trips CSV

    static func tripsCSV(_ trips: [Trip], unit: DistanceUnit) -> String {
        var lines: [String] = []
        lines.append(row(["Date", "Purpose", "From", "To",
                          "Distance (\(unit.shortLabel))", "Round trip",
                          "Vehicle", "Notes"]))
        for trip in trips.sorted(by: { $0.date < $1.date }) {
            let dist = unit.fromMiles(trip.effectiveMiles)
            lines.append(row([
                DateFormatting.iso.string(from: trip.date),
                trip.purpose.rawValue,
                trip.fromLabel,
                trip.toLabel,
                String(format: "%.2f", dist),
                trip.roundTrip ? "Yes" : "No",
                trip.vehicle?.name ?? "",
                trip.notes
            ]))
        }
        return lines.joined(separator: "\r\n")
    }

    // MARK: - Expenses CSV

    static func expensesCSV(_ expenses: [Expense], currencyCode: String) -> String {
        var lines: [String] = []
        lines.append(row(["Date", "Category", "Amount (\(currencyCode))",
                          "Deductible", "Vehicle", "Notes"]))
        for e in expenses.sorted(by: { $0.date < $1.date }) {
            lines.append(row([
                DateFormatting.iso.string(from: e.date),
                e.displayCategory,
                decimalString(e.amount),
                e.deductible ? "Yes" : "No",
                e.vehicle?.name ?? "",
                e.notes
            ]))
        }
        return lines.joined(separator: "\r\n")
    }

    // MARK: - Combined year summary CSV

    static func summaryCSV(result: DeductionResult,
                           comparison: MethodComparison,
                           currencyCode: String) -> String {
        var lines: [String] = []
        lines.append(row(["Furlong tax-year summary", "\(result.year)"]))
        lines.append(row(["Metric", "Value"]))
        lines.append(row(["Total deduction (\(currencyCode))", decimalString(result.totalDeduction)]))
        lines.append(row(["Mileage deduction", decimalString(result.totalMileageDeduction)]))
        lines.append(row(["Deductible expenses", decimalString(result.totalDeductibleExpenses)]))
        lines.append(row(["Business miles", String(format: "%.1f", result.businessMiles)]))
        lines.append(row(["Total miles", String(format: "%.1f", result.totalMiles)]))
        lines.append(row(["Business-use %", "\(Int((result.businessUsePercent * 100).rounded()))"]))
        lines.append(row([]))
        lines.append(row(["Mileage by purpose", "Miles", "Deduction"]))
        for purpose in TripPurpose.allCases where purpose.isDeductible {
            let miles = result.milesByPurpose[purpose] ?? 0
            let amount = result.mileageDeductionByPurpose[purpose] ?? 0
            lines.append(row([purpose.rawValue, String(format: "%.1f", miles), decimalString(amount)]))
        }
        lines.append(row([]))
        lines.append(row(["Method comparison", "Amount"]))
        lines.append(row(["Standard mileage", decimalString(comparison.standardMileageAmount)]))
        lines.append(row(["Actual expense", decimalString(comparison.actualExpenseAmount)]))
        lines.append(row(["Recommended", comparison.recommended]))
        return lines.joined(separator: "\r\n")
    }

    // MARK: - Plain-text report

    static func plainTextReport(result: DeductionResult,
                                comparison: MethodComparison,
                                settings: AppSettings) -> String {
        var out = ""
        out += "FURLONG — Tax Year \(result.year)\n"
        out += "================================\n\n"
        out += "Total deduction: \(settings.money(result.totalDeduction))\n"
        out += "  • Mileage:  \(settings.money(result.totalMileageDeduction))\n"
        out += "  • Expenses: \(settings.money(result.totalDeductibleExpenses))\n\n"
        out += "Business use: \(NumberFormatting.percent(result.businessUsePercent))"
        out += " (\(settings.distance(result.businessMiles)) of \(settings.distance(result.totalMiles)))\n"
        out += "Trips logged: \(result.tripCount)   Expenses logged: \(result.expenseCount)\n\n"

        out += "MILEAGE BY PURPOSE\n"
        for purpose in TripPurpose.allCases where purpose.isDeductible {
            let miles = result.milesByPurpose[purpose] ?? 0
            let amount = result.mileageDeductionByPurpose[purpose] ?? 0
            out += "  \(purpose.rawValue): \(settings.distance(miles)) → \(settings.money(amount))\n"
        }
        out += "\nDEDUCTIBLE EXPENSES BY CATEGORY\n"
        if result.deductibleExpensesByCategory.isEmpty {
            out += "  (none)\n"
        } else {
            let sorted = result.deductibleExpensesByCategory.sorted { $0.value > $1.value }
            for (cat, amount) in sorted {
                out += "  \(cat.rawValue): \(settings.money(amount))\n"
            }
        }
        out += "\nMETHOD COMPARISON (business use)\n"
        out += "  Standard mileage: \(settings.money(comparison.standardMileageAmount))\n"
        out += "  Actual expense:   \(settings.money(comparison.actualExpenseAmount))\n"
        out += "  Recommended:      \(comparison.recommended)\n\n"
        out += "Generated by Furlong. Standard IRS mileage rates; verify with a tax professional.\n"
        return out
    }
}
