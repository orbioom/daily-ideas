import SwiftUI

/// Holds the editable Calculator form state as raw text + structured pickers,
/// and recomputes the live `PaycheckResult` on every change. `@Observable`,
/// stored with `@State` by the owning view.
@Observable
final class CalculatorModel {

    // Pickers
    var payType: PayType = .salary
    var frequency: PayFrequency = .biweekly
    var filing: FilingStatus = .single
    var stateCode: String = "CA"

    // Raw text fields (validated on parse)
    var salaryText: String = "95000"
    var rateText: String = "30"
    var hoursText: String = "40"

    var pct401kText: String = "6"
    var dollar401kText: String = "0"
    var hsaText: String = "0"
    var healthText: String = "0"
    var otherPretaxText: String = "0"

    var postTaxText: String = "0"
    var extraWithholdingText: String = "0"

    /// Optional name when saving as a scenario.
    var scenarioName: String = ""

    // MARK: - Derived state

    var state: USState { StateTaxTable.state(forCode: stateCode) }

    /// Builds a validated engine input from the current form.
    var input: PaycheckInput {
        PaycheckInput.make(
            payType: payType,
            hourlyRate: Parse.decimalOrZero(rateText),
            hoursPerWeek: Parse.decimalOrZero(hoursText),
            annualSalary: Parse.decimalOrZero(salaryText),
            frequency: frequency,
            status: filing,
            state: state,
            pretax401kPercent: Parse.decimalOrZero(pct401kText) / 100,
            pretax401kDollar: Parse.decimalOrZero(dollar401kText),
            hsaAnnual: Parse.decimalOrZero(hsaText),
            healthPremiumPerPay: Parse.decimalOrZero(healthText),
            otherPretaxPerPay: Parse.decimalOrZero(otherPretaxText),
            postTaxPerPay: Parse.decimalOrZero(postTaxText),
            extraWithholdingPerPay: Parse.decimalOrZero(extraWithholdingText)
        )
    }

    /// The live result for the current form.
    var result: PaycheckResult { PaycheckEngine.compute(input) }

    /// True when the inputs describe a non-zero job (used to gate the hero card).
    var hasMeaningfulInput: Bool {
        PaycheckEngine.annualGross(for: input) > 0
    }

    // MARK: - Validation messages (non-blocking, friendly)

    /// A user-facing validation note, or nil when the form is fine.
    var validationNote: String? {
        switch payType {
        case .salary:
            if Parse.decimal(salaryText) == nil { return "Enter a salary amount to see your take-home." }
        case .hourly:
            if Parse.decimal(rateText) == nil { return "Enter an hourly rate to continue." }
            if Parse.decimal(hoursText) == nil || Parse.decimalOrZero(hoursText) == 0 {
                return "Enter hours per week (greater than zero)."
            }
        }
        return nil
    }

    // MARK: - Apply defaults & load scenarios

    /// Seeds the form defaults from user preferences (first appearance).
    func applyDefaults(_ prefs: AppPreferences) {
        filing = prefs.defaultFiling
        stateCode = prefs.defaultStateCode
        frequency = prefs.defaultFrequency
    }

    /// Loads a saved scenario into the form for editing / recompute.
    func load(from scenario: PayScenario) {
        payType = scenario.payType
        frequency = scenario.payFrequency
        filing = scenario.filingStatus
        stateCode = scenario.stateCode
        salaryText = Self.trimmed(scenario.annualSalary)
        rateText = Self.trimmed(scenario.rate)
        hoursText = Self.trimmed(scenario.hoursPerWeek)
        pct401kText = Self.trimmed(scenario.pretax401kPercent)
        dollar401kText = Self.trimmed(scenario.pretax401kDollar)
        hsaText = Self.trimmed(scenario.hsaAnnual)
        healthText = Self.trimmed(scenario.healthPremiumPerPay)
        otherPretaxText = Self.trimmed(scenario.otherPretaxPerPay)
        postTaxText = Self.trimmed(scenario.postTaxPerPay)
        extraWithholdingText = Self.trimmed(scenario.extraWithholdingPerPay)
        scenarioName = scenario.name
    }

    /// Builds a new PayScenario from the current form.
    func makeScenario(name: String) -> PayScenario {
        PayScenario(
            name: name,
            payType: payType,
            payFrequency: frequency,
            filingStatus: filing,
            stateCode: stateCode,
            rate: Parse.decimalOrZero(rateText).doubleValue,
            hoursPerWeek: Parse.decimalOrZero(hoursText).doubleValue,
            annualSalary: Parse.decimalOrZero(salaryText).doubleValue,
            pretax401kPercent: Parse.decimalOrZero(pct401kText).doubleValue,
            pretax401kDollar: Parse.decimalOrZero(dollar401kText).doubleValue,
            hsaAnnual: Parse.decimalOrZero(hsaText).doubleValue,
            healthPremiumPerPay: Parse.decimalOrZero(healthText).doubleValue,
            otherPretaxPerPay: Parse.decimalOrZero(otherPretaxText).doubleValue,
            postTaxPerPay: Parse.decimalOrZero(postTaxText).doubleValue,
            extraWithholdingPerPay: Parse.decimalOrZero(extraWithholdingText).doubleValue
        )
    }

    /// A nice default name, e.g. "$95,000 • CA".
    var suggestedName: String {
        let gross = PaycheckEngine.annualGross(for: input)
        return "\(Format.currency(gross, whole: true)) • \(stateCode)"
    }

    private static func trimmed(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(value)
    }
}
