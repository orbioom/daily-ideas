import Foundation

// MARK: - Engine input

/// A fully-resolved, validated set of inputs for one paycheck estimate.
/// All monetary values are annualized where noted. Negative inputs are clamped
/// to zero by `PaycheckInput.make` so the engine never sees bad data.
struct PaycheckInput {
    var payType: PayType
    var hourlyRate: Decimal        // $/hour
    var hoursPerWeek: Decimal      // hours worked per week
    var annualSalary: Decimal      // $/year
    var frequency: PayFrequency
    var status: FilingStatus
    var state: USState

    // Pre-tax deductions (per the documented treatment below)
    var pretax401kPercent: Decimal     // 0...1 fraction of gross
    var pretax401kDollar: Decimal      // flat $/year to 401(k)
    var hsaAnnual: Decimal             // $/year to HSA
    var healthPremiumPerPay: Decimal   // $ per paycheck (Section-125)
    var otherPretaxPerPay: Decimal     // $ per paycheck, income-tax-only pre-tax

    // Post-tax
    var postTaxPerPay: Decimal         // $ per paycheck deducted after tax
    var extraWithholdingPerPay: Decimal // additional federal withholding $ per paycheck

    /// Builds an input from raw (possibly invalid) values, clamping negatives to zero.
    static func make(
        payType: PayType,
        hourlyRate: Decimal,
        hoursPerWeek: Decimal,
        annualSalary: Decimal,
        frequency: PayFrequency,
        status: FilingStatus,
        state: USState,
        pretax401kPercent: Decimal,
        pretax401kDollar: Decimal,
        hsaAnnual: Decimal,
        healthPremiumPerPay: Decimal,
        otherPretaxPerPay: Decimal,
        postTaxPerPay: Decimal,
        extraWithholdingPerPay: Decimal
    ) -> PaycheckInput {
        func clamp(_ v: Decimal) -> Decimal { max(0, v) }
        // 401k percent is a fraction 0...1 (UI supplies 0...100 then divides).
        let pct = min(max(0, pretax401kPercent), 1)
        return PaycheckInput(
            payType: payType,
            hourlyRate: clamp(hourlyRate),
            hoursPerWeek: clamp(hoursPerWeek),
            annualSalary: clamp(annualSalary),
            frequency: frequency,
            status: status,
            state: state,
            pretax401kPercent: pct,
            pretax401kDollar: clamp(pretax401kDollar),
            hsaAnnual: clamp(hsaAnnual),
            healthPremiumPerPay: clamp(healthPremiumPerPay),
            otherPretaxPerPay: clamp(otherPretaxPerPay),
            postTaxPerPay: clamp(postTaxPerPay),
            extraWithholdingPerPay: clamp(extraWithholdingPerPay)
        )
    }
}

// MARK: - Engine result

/// Everything the UI needs to present an estimate. All values are annualized
/// unless the name says `perPaycheck`.
struct PaycheckResult: Equatable {
    var annualGross: Decimal

    // Pre-tax buckets (annualized)
    var contrib401k: Decimal
    var hsa: Decimal
    var healthPremiums: Decimal     // Section-125, reduces FICA too
    var otherPretax: Decimal        // income-tax-only

    var federalTaxableIncome: Decimal   // after pre-tax & standard deduction
    var ficaWages: Decimal              // wages subject to FICA

    var federalTax: Decimal
    var stateTax: Decimal
    var socialSecurity: Decimal
    var medicare: Decimal               // includes additional Medicare

    var extraWithholdingAnnual: Decimal
    var postTaxAnnual: Decimal

    /// Total of all taxes (fed + state + SS + Medicare). Excludes voluntary deductions.
    var totalTax: Decimal { federalTax + stateTax + socialSecurity + medicare + extraWithholdingAnnual }

    /// Net take-home pay for the year (after taxes, pre-tax & post-tax deductions).
    var netAnnual: Decimal

    var frequency: PayFrequency

    /// Net pay in one paycheck.
    var netPerPaycheck: Decimal {
        Self.divide(netAnnual, by: Decimal(frequency.periodsPerYear))
    }

    var grossPerPaycheck: Decimal {
        Self.divide(annualGross, by: Decimal(frequency.periodsPerYear))
    }

    var totalTaxPerPaycheck: Decimal {
        Self.divide(totalTax, by: Decimal(frequency.periodsPerYear))
    }

    /// Effective tax rate = total tax / annual gross (0 if gross is 0).
    var effectiveTaxRate: Decimal {
        annualGross > 0 ? Self.divide(totalTax, by: annualGross) : 0
    }

    /// Take-home percentage of gross.
    var takeHomePercent: Decimal {
        annualGross > 0 ? Self.divide(netAnnual, by: annualGross) : 0
    }

    /// Marginal federal rate at this income (top bracket touched). 0...0.37.
    var marginalFederalRate: Decimal

    var totalPretax: Decimal { contrib401k + hsa + healthPremiums + otherPretax }

    /// Safe division that returns 0 when the divisor is zero.
    static func divide(_ a: Decimal, by b: Decimal) -> Decimal {
        b == 0 ? 0 : a / b
    }
}

// MARK: - The engine

/// Pure, deterministic 2025 take-home pay estimator. No I/O, no side effects.
///
/// Pre-tax treatment (documented & transparent):
/// - 401(k): reduces **federal & state** taxable income only — NOT FICA wages.
/// - HSA: reduces federal & state taxable income AND FICA wages (cafeteria plan).
/// - Health premiums (Section-125): reduce federal & state taxable income AND FICA wages.
/// - Other pre-tax: treated like 401(k) — income tax only.
enum PaycheckEngine {

    /// Computes the full estimate for a single input.
    static func compute(_ input: PaycheckInput) -> PaycheckResult {
        // 1. Annual gross
        let annualGross = annualGross(for: input)

        // 2. Annualize per-paycheck pre-tax items
        let periods = Decimal(input.frequency.periodsPerYear)
        let healthAnnual = input.healthPremiumPerPay * periods
        let otherPretaxAnnual = input.otherPretaxPerPay * periods

        // 3. 401(k): percent of gross + flat dollar, capped at gross
        let percentContribution = annualGross * input.pretax401kPercent
        let raw401k = percentContribution + input.pretax401kDollar
        let contrib401k = min(raw401k, annualGross)

        let hsa = min(input.hsaAnnual, max(0, annualGross - contrib401k))

        // 4. FICA wages: gross minus the pre-tax items that reduce FICA (HSA + premiums)
        let ficaReducers = hsa + healthAnnual
        let ficaWages = max(0, annualGross - ficaReducers)

        // 5. Income-tax pre-tax total: all four buckets reduce income tax
        let incomeTaxPretax = contrib401k + hsa + healthAnnual + otherPretaxAnnual
        let wagesAfterPretax = max(0, annualGross - incomeTaxPretax)

        // 6. Federal taxable income = wages after pre-tax − standard deduction
        let standardDeduction = TaxTables2025.standardDeduction(input.status)
        let federalTaxable = max(0, wagesAfterPretax - standardDeduction)

        // 7. Federal income tax (progressive)
        let federalTax = federalIncomeTax(taxable: federalTaxable, status: input.status)
        let marginal = marginalFederalRate(taxable: federalTaxable, status: input.status)

        // 8. State income tax — flat approximation on the same taxable base
        let stateTax = (federalTaxable * input.state.effectiveRate).rounded2()

        // 9. FICA
        let ss = socialSecurityTax(ficaWages: ficaWages)
        let medicare = medicareTax(ficaWages: ficaWages, status: input.status)

        // 10. Post-tax & extra withholding, annualized
        let extraWithholdingAnnual = input.extraWithholdingPerPay * periods
        let postTaxAnnual = input.postTaxPerPay * periods

        // 11. Net = gross − pre-tax − taxes − extra withholding − post-tax
        let totalTax = federalTax + stateTax + ss + medicare + extraWithholdingAnnual
        let net = max(0, annualGross - incomeTaxPretax - totalTax - postTaxAnnual)

        return PaycheckResult(
            annualGross: annualGross.rounded2(),
            contrib401k: contrib401k.rounded2(),
            hsa: hsa.rounded2(),
            healthPremiums: healthAnnual.rounded2(),
            otherPretax: otherPretaxAnnual.rounded2(),
            federalTaxableIncome: federalTaxable.rounded2(),
            ficaWages: ficaWages.rounded2(),
            federalTax: federalTax.rounded2(),
            stateTax: stateTax,
            socialSecurity: ss.rounded2(),
            medicare: medicare.rounded2(),
            extraWithholdingAnnual: extraWithholdingAnnual.rounded2(),
            postTaxAnnual: postTaxAnnual.rounded2(),
            netAnnual: net.rounded2(),
            frequency: input.frequency,
            marginalFederalRate: marginal
        )
    }

    // MARK: Gross

    static func annualGross(for input: PaycheckInput) -> Decimal {
        switch input.payType {
        case .salary:
            return max(0, input.annualSalary)
        case .hourly:
            // rate × hours/week × 52 weeks
            return max(0, input.hourlyRate * input.hoursPerWeek * 52)
        }
    }

    // MARK: Federal income tax (progressive)

    /// Applies the progressive bracket schedule to taxable income.
    static func federalIncomeTax(taxable: Decimal, status: FilingStatus) -> Decimal {
        guard taxable > 0 else { return 0 }
        let brackets = TaxTables2025.federalBrackets(status)
        var tax: Decimal = 0
        for (index, bracket) in brackets.enumerated() {
            let lower = bracket.lowerBound
            guard taxable > lower else { break }
            // Upper edge is the next bracket's lower bound (or income itself for the top).
            let upper: Decimal
            if index + 1 < brackets.count {
                upper = brackets[index + 1].lowerBound
            } else {
                upper = taxable
            }
            let bandTop = min(taxable, upper)
            let amountInBand = max(0, bandTop - lower)
            tax += amountInBand * bracket.rate
        }
        return max(0, tax)
    }

    /// The marginal federal rate — the rate of the top bracket the income reaches.
    static func marginalFederalRate(taxable: Decimal, status: FilingStatus) -> Decimal {
        let brackets = TaxTables2025.federalBrackets(status)
        var rate: Decimal = brackets.first?.rate ?? 0
        for bracket in brackets where taxable > bracket.lowerBound {
            rate = bracket.rate
        }
        return taxable > 0 ? rate : 0
    }

    // MARK: FICA

    static func socialSecurityTax(ficaWages: Decimal) -> Decimal {
        let taxable = min(max(0, ficaWages), TaxTables2025.socialSecurityWageBase)
        return taxable * TaxTables2025.socialSecurityRate
    }

    static func medicareTax(ficaWages: Decimal, status: FilingStatus) -> Decimal {
        let wages = max(0, ficaWages)
        let base = wages * TaxTables2025.medicareRate
        let threshold = TaxTables2025.additionalMedicareThreshold(status)
        let over = max(0, wages - threshold)
        let additional = over * TaxTables2025.additionalMedicareRate
        return base + additional
    }
}

// MARK: - Decimal rounding helper

extension Decimal {
    /// Rounds to 2 decimal places (bankers-safe, plain rounding) for currency.
    func rounded2() -> Decimal {
        var result = Decimal()
        var copy = self
        NSDecimalRound(&result, &copy, 2, .plain)
        return result
    }

    /// Double value for charting / formatting only (never for money math).
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
