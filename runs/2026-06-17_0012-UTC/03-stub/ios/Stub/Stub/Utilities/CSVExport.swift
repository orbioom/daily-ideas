import Foundation

/// Builds a CSV string of saved scenarios and their computed results.
enum CSVExport {
    static func string(for scenarios: [PayScenario], roundWhole: Bool) -> String {
        var rows: [String] = []
        rows.append([
            "Name", "Pay type", "Frequency", "Filing", "State",
            "Annual gross", "Federal tax", "State tax", "Social Security",
            "Medicare", "Total tax", "Net annual", "Net per paycheck",
            "Effective rate", "Take-home %"
        ].joined(separator: ","))

        for scenario in scenarios {
            let r = scenario.result
            let fields = [
                escape(scenario.name),
                scenario.payType.label,
                scenario.payFrequency.shortLabel,
                scenario.filingStatus.shortLabel,
                scenario.stateCode,
                plain(r.annualGross),
                plain(r.federalTax),
                plain(r.stateTax),
                plain(r.socialSecurity),
                plain(r.medicare),
                plain(r.totalTax),
                plain(r.netAnnual),
                plain(r.netPerPaycheck),
                percent(r.effectiveTaxRate),
                percent(r.takeHomePercent)
            ]
            rows.append(fields.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func plain(_ value: Decimal) -> String {
        let n = NSDecimalNumber(decimal: value.rounded2())
        return n.stringValue
    }

    private static func percent(_ fraction: Decimal) -> String {
        let n = NSDecimalNumber(decimal: (fraction * 100).rounded2())
        return n.stringValue + "%"
    }

    /// Escapes a CSV field containing commas or quotes.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return field
    }
}
