import SwiftUI

/// Drives the EstimateView. Holds editable inputs as strings (for text fields) and
/// recomputes a TaxEstimate live. Pure-ish: no SwiftData here — the view passes in
/// ledger totals when the user chooses to pull them.
@Observable
final class EstimateViewModel {

    // Raw text-field strings (parsed defensively).
    var incomeText: String = ""
    var expensesText: String = ""
    var otherW2Text: String = ""
    var withholdingText: String = ""
    var stateRateText: String = ""

    var filingStatus: FilingStatus = .single
    var year: Int = 2025

    /// Tracks whether the user has typed anything yet (for the empty/idle state).
    var hasInput: Bool {
        !(incomeText.isEmpty && expensesText.isEmpty && otherW2Text.isEmpty
          && withholdingText.isEmpty && stateRateText.isEmpty)
    }

    // Parsed Decimals (blank or garbage -> 0).
    var incomeValue: Decimal { Self.parse(incomeText) }
    var expensesValue: Decimal { Self.parse(expensesText) }
    var otherW2Value: Decimal { Self.parse(otherW2Text) }
    var withholdingValue: Decimal { Self.parse(withholdingText) }
    var stateRateValue: Decimal { Self.parse(stateRateText) }

    var inputs: TaxInputs {
        TaxInputs(
            year: year,
            filingStatus: filingStatus,
            selfEmploymentIncome: incomeValue,
            businessExpenses: expensesValue,
            otherW2Income: otherW2Value,
            federalWithholding: withholdingValue,
            stateRatePct: stateRateValue
        )
    }

    var estimate: TaxEstimate { TaxEngine.estimate(inputs) }

    /// Has the user supplied enough to produce a meaningful number?
    var isComputable: Bool { incomeValue > 0 || otherW2Value > 0 }

    /// Pull income/expense totals from the ledger.
    func applyLedger(incomeTotal: Double, expenseTotal: Double) {
        incomeText = Self.formatPlain(incomeTotal)
        expensesText = Self.formatPlain(expenseTotal)
        Haptics.tap()
    }

    /// Seed from saved defaults.
    func applyDefaults(filingStatusRaw: String, stateRate: Double, year: Int) {
        self.filingStatus = FilingStatus(rawValue: filingStatusRaw) ?? .single
        self.year = year
        if stateRateText.isEmpty && stateRate > 0 {
            self.stateRateText = Self.formatPlain(stateRate)
        }
    }

    // MARK: - Parsing helpers

    /// Parse a user string into a non-negative Decimal. Strips currency symbols,
    /// commas, and whitespace. Returns 0 on anything unparseable.
    static func parse(_ text: String) -> Decimal {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned) else { return 0 }
        return max(0, value)
    }

    static func formatPlain(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
