import SwiftUI
import Observation

/// Holds the editable string inputs for the Calculator and derives a live `LoanInput`
/// + `PaymentBreakdown`. All parsing is guarded; invalid fields fall back to 0.
@Observable
final class CalculatorModel {

    // Raw text fields (so we can show inline validation).
    var homePriceText: String
    var downPaymentText: String
    var downIsPercent: Bool          // toggle: interpret down payment as % or $
    var rateText: String
    var termYears: Int
    var propertyTaxText: String
    var annualInsuranceText: String
    var monthlyHOAText: String
    var extraMonthlyText: String

    /// Seeds defaults from AppSettings on first construction.
    init(settings: AppSettings) {
        homePriceText = "350000"
        downPaymentText = "20"
        downIsPercent = true
        rateText = Self.trimmed(settings.defaultRatePct)
        termYears = settings.defaultTermYears
        propertyTaxText = Self.trimmed(settings.defaultPropertyTaxPct)
        annualInsuranceText = "1500"
        monthlyHOAText = "0"
        extraMonthlyText = "0"
    }

    private static func trimmed(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(value)
    }

    /// The resolved down-payment amount in currency (handles the %/$ toggle).
    var downPaymentAmount: Decimal {
        let price = Parse.decimalOrZero(homePriceText)
        let raw = Parse.decimalOrZero(downPaymentText)
        if downIsPercent {
            return (price * min(raw, 100) / 100).rounded(2)
        }
        return min(raw, price)
    }

    /// The validated Decimal loan input derived from the current fields.
    var loanInput: LoanInput {
        LoanInput.make(
            homePrice: Parse.decimalOrZero(homePriceText),
            downPayment: downPaymentAmount,
            annualRatePct: Parse.decimalOrZero(rateText),
            termYears: termYears,
            propertyTaxPct: Parse.decimalOrZero(propertyTaxText),
            annualInsurance: Parse.decimalOrZero(annualInsuranceText),
            monthlyHOA: Parse.decimalOrZero(monthlyHOAText),
            extraMonthly: Parse.decimalOrZero(extraMonthlyText)
        )
    }

    /// The live monthly breakdown.
    var breakdown: PaymentBreakdown { MortgageEngine.breakdown(loanInput) }

    /// Whether the inputs describe a real loan (price & principal present).
    var hasValidLoan: Bool {
        loanInput.homePrice > 0 && loanInput.principal > 0
    }

    /// The down-payment percentage (for display), 0...100.
    var downPercent: Decimal {
        let price = loanInput.homePrice
        guard price > 0 else { return 0 }
        return (MortgageEngine.divide(loanInput.downPayment, by: price) * 100).rounded(1)
    }

    /// Loads the fields from a saved scenario.
    func load(from scenario: MortgageScenario) {
        homePriceText = Self.trimmed(scenario.homePrice)
        downPaymentText = Self.trimmed(scenario.downPayment)
        downIsPercent = false
        rateText = Self.trimmed(scenario.annualRatePct)
        termYears = scenario.termYears
        propertyTaxText = Self.trimmed(scenario.propertyTaxPct)
        annualInsuranceText = Self.trimmed(scenario.annualInsurance)
        monthlyHOAText = Self.trimmed(scenario.monthlyHOA)
        extraMonthlyText = Self.trimmed(scenario.extraMonthly)
    }

    /// Builds a new scenario model from the current fields.
    func makeScenario(name: String) -> MortgageScenario {
        let input = loanInput
        return MortgageScenario(
            name: name,
            homePrice: input.homePrice.doubleValue,
            downPayment: input.downPayment.doubleValue,
            annualRatePct: input.annualRatePct.doubleValue,
            termYears: input.termYears,
            propertyTaxPct: input.propertyTaxPct.doubleValue,
            annualInsurance: input.annualInsurance.doubleValue,
            monthlyHOA: input.monthlyHOA.doubleValue,
            extraMonthly: input.extraMonthly.doubleValue
        )
    }

    /// Term options offered as chips.
    static let termOptions: [(value: Int, label: String)] = [
        (10, "10 yr"), (15, "15 yr"), (20, "20 yr"), (30, "30 yr")
    ]
}
