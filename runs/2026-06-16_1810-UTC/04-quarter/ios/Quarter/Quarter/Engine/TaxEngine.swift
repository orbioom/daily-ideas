import Foundation

/// Inputs to a full estimate. All money is plain Decimal here (converted from the
/// Double-backed SwiftData models at the call site).
struct TaxInputs {
    var year: Int
    var filingStatus: FilingStatus
    var selfEmploymentIncome: Decimal      // gross 1099 / business income
    var businessExpenses: Decimal
    var otherW2Income: Decimal
    var federalWithholding: Decimal
    var stateRatePct: Decimal              // user-entered flat approximation, e.g. 5.0

    init(year: Int = 2025,
         filingStatus: FilingStatus = .single,
         selfEmploymentIncome: Decimal = 0,
         businessExpenses: Decimal = 0,
         otherW2Income: Decimal = 0,
         federalWithholding: Decimal = 0,
         stateRatePct: Decimal = 0) {
        self.year = year
        self.filingStatus = filingStatus
        self.selfEmploymentIncome = selfEmploymentIncome
        self.businessExpenses = businessExpenses
        self.otherW2Income = otherW2Income
        self.federalWithholding = federalWithholding
        self.stateRatePct = stateRatePct
    }
}

/// Full estimate result. All Decimal; views format these.
struct TaxEstimate {
    var year: Int
    var filingStatus: FilingStatus

    var netSE: Decimal
    var seBase: Decimal
    var socialSecurityTax: Decimal
    var medicareTax: Decimal
    var additionalMedicareTax: Decimal
    var seTax: Decimal
    var halfSEDeduction: Decimal

    var agi: Decimal
    var standardDeduction: Decimal
    var taxableIncome: Decimal
    var federalIncomeTax: Decimal
    var stateTax: Decimal
    var totalTax: Decimal

    var grossIncome: Decimal           // SE income + other W-2 (before expenses)
    var federalWithholding: Decimal
    var balanceDueOrRefund: Decimal    // positive = owe, negative = refund

    var effectiveRate: Decimal         // fraction (totalTax / gross), 0 when gross 0
    var marginalRate: Decimal          // top bracket rate hit
    var setAsidePercent: Decimal       // rounded-up tidy % of gross to set aside (fraction)

    var owes: Bool { balanceDueOrRefund > 0 }
}

/// Pure, deterministic tax engine. No I/O, no SwiftData. All arithmetic in Decimal.
enum TaxEngine {

    // Rates
    static let socialSecurityRate: Decimal = 0.124   // 12.4%
    static let medicareRate: Decimal = 0.029         // 2.9%
    static let additionalMedicareRate: Decimal = 0.009 // 0.9%
    static let seBaseFactor: Decimal = 0.9235        // 92.35%

    /// Compute the full estimate. Every division is guarded.
    static func estimate(_ input: TaxInputs) -> TaxEstimate {
        let data = TaxTables.data(for: input.year)
        let status = input.filingStatus

        // 1. Net self-employment profit (never negative).
        let netSE = max(0, input.selfEmploymentIncome - input.businessExpenses)

        // 2. SE base (subject to SE tax).
        let seBase = netSE * seBaseFactor

        // 3. Social Security portion — capped at the wage base.
        let ssTaxable = min(seBase, data.socialSecurityWageBase)
        let socialSecurityTax = socialSecurityRate * max(0, ssTaxable)

        // 4. Medicare portion — uncapped.
        let medicareTax = medicareRate * seBase

        // 5. Additional Medicare 0.9% over the status threshold.
        let amBase = max(0, (seBase + input.otherW2Income) - status.additionalMedicareThreshold)
        let additionalMedicareTax = additionalMedicareRate * amBase

        // 6. Total SE tax.
        let seTax = socialSecurityTax + medicareTax + additionalMedicareTax

        // 7. Deduction for half of SE tax (SS + Medicare only; not the additional 0.9%).
        let halfSEDeduction = (socialSecurityTax + medicareTax) / 2

        // 8. AGI.
        let agi = netSE + input.otherW2Income - halfSEDeduction

        // 9. Taxable income after the standard deduction.
        let standardDeduction = data.standardDeduction(for: status)
        let taxableIncome = max(0, agi - standardDeduction)

        // 10. Progressive federal income tax.
        let federalIncomeTax = progressiveTax(on: taxableIncome,
                                              brackets: data.brackets(for: status))

        // 11. State tax — flat user approximation. stateRatePct is a whole percent.
        let stateTax = max(0, taxableIncome) * (input.stateRatePct / 100)

        // 12. Totals.
        let totalTax = federalIncomeTax + seTax + stateTax
        let grossIncome = input.selfEmploymentIncome + input.otherW2Income
        let balance = totalTax - input.federalWithholding

        // 13. Rates — guarded against zero gross income.
        let effectiveRate: Decimal = grossIncome > 0 ? (totalTax / grossIncome) : 0
        let marginalRate = marginalBracketRate(for: taxableIncome,
                                               brackets: data.brackets(for: status))

        // 14. Set-aside recommendation — round the effective fraction UP to a tidy whole %.
        let setAside = grossIncome > 0 ? roundUpToTidyPercent(totalTax / grossIncome) : 0

        return TaxEstimate(
            year: input.year,
            filingStatus: status,
            netSE: netSE,
            seBase: seBase,
            socialSecurityTax: socialSecurityTax,
            medicareTax: medicareTax,
            additionalMedicareTax: additionalMedicareTax,
            seTax: seTax,
            halfSEDeduction: halfSEDeduction,
            agi: agi,
            standardDeduction: standardDeduction,
            taxableIncome: taxableIncome,
            federalIncomeTax: federalIncomeTax,
            stateTax: stateTax,
            totalTax: totalTax,
            grossIncome: grossIncome,
            federalWithholding: input.federalWithholding,
            balanceDueOrRefund: balance,
            effectiveRate: effectiveRate,
            marginalRate: marginalRate,
            setAsidePercent: setAside
        )
    }

    /// Marginal-bracket progressive tax. Sums tax owed in each bracket band.
    static func progressiveTax(on taxable: Decimal, brackets: [TaxBracket]) -> Decimal {
        guard taxable > 0 else { return 0 }
        var tax: Decimal = 0
        for bracket in brackets {
            guard taxable > bracket.lowerBound else { break }
            let upper = bracket.upperBound ?? taxable
            let bandTop = min(taxable, upper)
            let bandAmount = bandTop - bracket.lowerBound
            if bandAmount > 0 {
                tax += bandAmount * bracket.rate
            }
        }
        return tax
    }

    /// The top marginal rate the taxable income reaches.
    static func marginalBracketRate(for taxable: Decimal, brackets: [TaxBracket]) -> Decimal {
        guard taxable > 0 else { return brackets.first?.rate ?? 0 }
        var rate: Decimal = brackets.first?.rate ?? 0
        for bracket in brackets {
            if taxable > bracket.lowerBound {
                rate = bracket.rate
            } else {
                break
            }
        }
        return rate
    }

    /// Round a fraction (e.g. 0.214) up to a tidy whole percent fraction (0.25 -> 25%).
    /// Uses 5-percentage-point steps for a memorable "set aside X%".
    static func roundUpToTidyPercent(_ fraction: Decimal) -> Decimal {
        guard fraction > 0 else { return 0 }
        let pct = fraction * 100
        // Round UP to the next multiple of 5.
        let step: Decimal = 5
        let divided = pct / step
        let ceiled = divided.rounded(0, .up)
        let tidyPct = ceiled * step
        // Cap at a sensible ceiling so the recommendation stays reasonable.
        let capped = min(tidyPct, 50)
        return capped / 100
    }
}
