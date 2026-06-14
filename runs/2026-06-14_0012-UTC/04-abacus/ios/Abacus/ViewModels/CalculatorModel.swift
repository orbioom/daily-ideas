import SwiftUI
import SwiftData

/// Shared, observable calculator state. Owned at the root so a saved scenario can
/// be loaded into it from the Scenarios tab, and the Amortization tab reads the
/// same inputs. Validation is computed; results are derived from the pure engine.
@Observable
final class CalculatorModel {
    var name: String = "New mortgage"
    var loanType: LoanType = .mortgage
    var principal: Double = 350_000
    var annualRatePct: Double = 6.25
    var termMonths: Int = 360
    var startDate: Date = .now
    var extraMonthly: Double = 0
    var extraOneTime: Double = 0
    var extraOneTimeMonth: Int = 0

    /// Tracks the scenario currently loaded (for "update" vs "save new").
    var loadedScenarioID: UUID? = nil

    // MARK: - Validation

    enum ValidationIssue: String, Identifiable {
        case principal = "Enter a loan amount greater than zero."
        case rate = "Enter an interest rate between 0% and 40%."
        case term = "Term must be between 1 and 600 months."
        case extraTooBig = "Extra monthly payment is larger than the loan itself."
        var id: String { rawValue }
    }

    var issues: [ValidationIssue] {
        var out: [ValidationIssue] = []
        if !(principal > 0) { out.append(.principal) }
        if annualRatePct < 0 || annualRatePct > 40 { out.append(.rate) }
        if termMonths < 1 || termMonths > 600 { out.append(.term) }
        if principal > 0, extraMonthly >= principal { out.append(.extraTooBig) }
        return out
    }

    var isValid: Bool { issues.isEmpty }
    var hasExtra: Bool { extraMonthly > 0 || (extraOneTime > 0 && extraOneTimeMonth > 0) }

    // MARK: - Derived results

    var summary: LoanSummary? {
        guard isValid else { return nil }
        return LoanMath.summarize(principal: principal,
                                  annualRatePct: annualRatePct,
                                  termMonths: termMonths,
                                  startDate: startDate,
                                  extraMonthly: extraMonthly,
                                  extraOneTime: extraOneTime,
                                  extraOneTimeMonth: extraOneTimeMonth)
    }

    func scheduleWithExtra() -> [AmortRow] {
        guard isValid else { return [] }
        return LoanMath.schedule(principal: principal,
                                 annualRatePct: annualRatePct,
                                 termMonths: termMonths,
                                 startDate: startDate,
                                 extraMonthly: extraMonthly,
                                 extraOneTime: extraOneTime,
                                 extraOneTimeMonth: extraOneTimeMonth)
    }

    func baselineSchedule() -> [AmortRow] {
        guard isValid else { return [] }
        return LoanMath.schedule(principal: principal,
                                 annualRatePct: annualRatePct,
                                 termMonths: termMonths,
                                 startDate: startDate)
    }

    // MARK: - Term unit helpers

    func termYears(roundingUp: Bool = false) -> Int {
        roundingUp ? Int((Double(termMonths) / 12.0).rounded(.up)) : termMonths / 12
    }

    // MARK: - Scenario IO

    func load(from scenario: LoanScenario) {
        name = scenario.name
        loanType = scenario.loanType
        principal = scenario.principal
        annualRatePct = scenario.annualRatePct
        termMonths = scenario.termMonths
        startDate = scenario.startDate
        extraMonthly = scenario.extraMonthly
        extraOneTime = scenario.extraOneTime
        extraOneTimeMonth = scenario.extraOneTimeMonth
        loadedScenarioID = scenario.id
    }

    /// Build a new persisted scenario from the current inputs.
    func makeScenario() -> LoanScenario {
        LoanScenario(name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? loanType.label + " loan" : name,
                     loanType: loanType,
                     principal: principal,
                     annualRatePct: annualRatePct,
                     termMonths: termMonths,
                     startDate: startDate,
                     extraMonthly: extraMonthly,
                     extraOneTime: extraOneTime,
                     extraOneTimeMonth: extraOneTimeMonth)
    }

    /// Copy current inputs onto an existing scenario (for in-place updates).
    func apply(to scenario: LoanScenario) {
        scenario.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? loanType.label + " loan" : name
        scenario.loanType = loanType
        scenario.principal = principal
        scenario.annualRatePct = annualRatePct
        scenario.termMonths = termMonths
        scenario.startDate = startDate
        scenario.extraMonthly = extraMonthly
        scenario.extraOneTime = extraOneTime
        scenario.extraOneTimeMonth = extraOneTimeMonth
    }

    /// Apply per-user defaults from Settings to a freshly-reset calculator.
    func applyDefaults(_ settings: AppSettings) {
        termMonths = settings.defaultTermMonths
        extraMonthly = settings.defaultExtraMonthly
    }
}
