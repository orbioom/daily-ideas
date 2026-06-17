import Foundation

// MARK: - Loan inputs

/// A validated, non-negative set of mortgage inputs. All money values are `Decimal`.
/// Use `LoanInput.make` so the engine never sees negative / nonsensical values.
struct LoanInput: Equatable {
    var homePrice: Decimal       // total purchase price
    var downPayment: Decimal     // down payment amount (currency)
    var annualRatePct: Decimal   // annual interest rate as a percentage, e.g. 6.5
    var termYears: Int           // amortization term in years
    var propertyTaxPct: Decimal  // annual property tax as a % of home value, e.g. 1.1
    var annualInsurance: Decimal // annual homeowners insurance ($)
    var monthlyHOA: Decimal      // monthly HOA dues ($)
    var extraMonthly: Decimal    // recurring extra principal per month ($)

    /// Loan principal = price − down payment (never negative).
    var principal: Decimal { max(0, homePrice - downPayment) }

    /// Number of payments (months). At least 1 to keep math safe.
    var months: Int { max(1, termYears * 12) }

    /// Loan-to-value at origination as a fraction (0...1). 0 when price is 0.
    var ltv: Decimal { homePrice > 0 ? MortgageEngine.divide(principal, homePrice) : 0 }

    /// Builds an input, clamping negatives and bounding the term to a sane range.
    static func make(
        homePrice: Decimal,
        downPayment: Decimal,
        annualRatePct: Decimal,
        termYears: Int,
        propertyTaxPct: Decimal,
        annualInsurance: Decimal,
        monthlyHOA: Decimal,
        extraMonthly: Decimal
    ) -> LoanInput {
        func clamp(_ v: Decimal) -> Decimal { max(0, v) }
        // Down payment cannot exceed the price.
        let price = clamp(homePrice)
        let down = min(clamp(downPayment), price)
        return LoanInput(
            homePrice: price,
            downPayment: down,
            annualRatePct: clamp(annualRatePct),
            termYears: min(max(1, termYears), 50),
            propertyTaxPct: clamp(propertyTaxPct),
            annualInsurance: clamp(annualInsurance),
            monthlyHOA: clamp(monthlyHOA),
            extraMonthly: clamp(extraMonthly)
        )
    }
}

// MARK: - Monthly payment breakdown (PITI + extras)

/// The full monthly housing payment, decomposed.
struct PaymentBreakdown: Equatable {
    var principalAndInterest: Decimal
    var propertyTax: Decimal
    var insurance: Decimal
    var pmi: Decimal
    var hoa: Decimal

    /// Grand total monthly payment (PITI + PMI + HOA).
    var total: Decimal { principalAndInterest + propertyTax + insurance + pmi + hoa }
}

// MARK: - One amortized month

/// A single month of the amortization schedule.
struct AmortizationRow: Identifiable, Equatable {
    let id: Int           // 1-based payment number (stable identity)
    let date: Date        // the month this payment lands on
    let payment: Decimal  // principal + interest actually paid this month
    let interest: Decimal
    let principal: Decimal
    let extra: Decimal    // extra principal applied this month
    let balance: Decimal  // remaining balance AFTER this payment
}

/// The result of building a full amortization schedule.
struct AmortizationResult: Equatable {
    var rows: [AmortizationRow]
    var totalInterest: Decimal
    var totalPaid: Decimal       // total principal + interest paid over life
    var payoffDate: Date
    var monthsToPayoff: Int
    /// The payment number after which PMI is dropped (balance ≤ 78% of original value), or nil.
    var pmiDropMonth: Int?
}

// MARK: - Refinance compare

struct RefinanceResult: Equatable {
    var currentPayment: Decimal     // current P&I
    var newPayment: Decimal         // new P&I
    var monthlySavings: Decimal     // current − new (positive = saves)
    var closingCosts: Decimal
    var breakEvenMonths: Int?       // nil if there is no monthly saving
    var currentLifetimeInterest: Decimal
    var newLifetimeInterest: Decimal
    /// New lifetime interest + closing costs minus current lifetime interest.
    var lifetimeInterestDelta: Decimal
}

// MARK: - Affordability

struct AffordabilityResult: Equatable {
    var maxHomePrice: Decimal
    var maxLoanAmount: Decimal
    var estimatedPayment: Decimal     // full monthly PITI at the max price
    var principalAndInterest: Decimal
    var frontEndDTI: Decimal          // resulting front-end ratio (0...1)
    var backEndDTI: Decimal           // resulting back-end ratio (0...1)
    var bindingConstraint: String     // which ratio limited the result
}

// MARK: - The engine

/// Pure, deterministic mortgage math. All currency math in `Decimal`. No I/O.
/// Every division and parse is guarded; no force-unwraps.
enum MortgageEngine {

    /// PMI annual rate as a fraction of the loan balance (industry-typical ~0.5%/yr).
    static let pmiAnnualRate: Decimal = 0.005
    /// PMI auto-cancels when the balance reaches this LTV (78% per the HPA).
    static let pmiDropLTV: Decimal = 0.78

    // MARK: Safe division

    /// Division that returns 0 when the divisor is zero — never traps.
    static func divide(_ a: Decimal, by b: Decimal) -> Decimal {
        b == 0 ? 0 : a / b
    }

    // MARK: Monthly principal & interest

    /// M = P·r(1+r)^n / ((1+r)^n − 1), with the r == 0 guard (M = P/n).
    static func monthlyPI(principal P: Decimal, annualRatePct: Decimal, months n: Int) -> Decimal {
        guard P > 0, n > 0 else { return 0 }
        let r = divide(annualRatePct / 100, by: 12)   // monthly rate fraction
        if r == 0 {
            return divide(P, by: Decimal(n)).rounded(2)
        }
        let onePlusR = 1 + r
        let pow = power(onePlusR, n)                   // (1+r)^n
        let denominator = pow - 1
        guard denominator != 0 else { return divide(P, by: Decimal(n)).rounded(2) }
        let payment = divide(P * r * pow, by: denominator)
        return payment.rounded(2)
    }

    /// Integer exponentiation for Decimal (n ≥ 0) — repeated multiply, no Double drift.
    static func power(_ base: Decimal, _ exponent: Int) -> Decimal {
        guard exponent > 0 else { return 1 }
        var result: Decimal = 1
        for _ in 0..<exponent { result *= base }
        return result
    }

    // MARK: Monthly property tax / insurance / PMI

    static func monthlyPropertyTax(homePrice: Decimal, annualTaxPct: Decimal) -> Decimal {
        divide(homePrice * (annualTaxPct / 100), by: 12).rounded(2)
    }

    static func monthlyInsurance(annualInsurance: Decimal) -> Decimal {
        divide(annualInsurance, by: 12).rounded(2)
    }

    /// Monthly PMI from the current balance (only applies while LTV > drop threshold).
    static func monthlyPMI(balance: Decimal) -> Decimal {
        divide(balance * pmiAnnualRate, by: 12).rounded(2)
    }

    /// Whether PMI applies at origination: down payment < 20% of price.
    static func pmiAppliesAtStart(_ input: LoanInput) -> Bool {
        guard input.homePrice > 0 else { return false }
        return input.ltv > (1 - 0.20)   // LTV > 80%
    }

    // MARK: Full payment breakdown (first-month snapshot)

    /// The headline monthly payment breakdown using the opening balance for PMI.
    static func breakdown(_ input: LoanInput) -> PaymentBreakdown {
        let pi = monthlyPI(principal: input.principal, annualRatePct: input.annualRatePct, months: input.months)
        let tax = monthlyPropertyTax(homePrice: input.homePrice, annualTaxPct: input.propertyTaxPct)
        let ins = monthlyInsurance(annualInsurance: input.annualInsurance)
        let pmi = pmiAppliesAtStart(input) ? monthlyPMI(balance: input.principal) : 0
        return PaymentBreakdown(
            principalAndInterest: pi,
            propertyTax: tax,
            insurance: ins,
            pmi: pmi,
            hoa: input.monthlyHOA.rounded(2)
        )
    }

    // MARK: Amortization schedule

    /// Builds the full amortization schedule with optional recurring extra principal.
    /// Caps iterations defensively so a pathological input can never spin forever.
    static func amortize(_ input: LoanInput,
                         extraMonthly: Decimal? = nil,
                         oneTimeExtra: Decimal = 0,
                         oneTimeMonth: Int = 1,
                         startDate: Date = Date()) -> AmortizationResult {
        let principal = input.principal
        let n = input.months
        let basePI = monthlyPI(principal: principal, annualRatePct: input.annualRatePct, months: n)
        let r = divide(input.annualRatePct / 100, by: 12)
        let extra = max(0, extraMonthly ?? input.extraMonthly)
        let pmiThresholdBalance = input.homePrice * pmiDropLTV   // balance at which PMI drops

        var rows: [AmortizationRow] = []
        rows.reserveCapacity(min(n + 12, 700))
        var balance = principal
        var totalInterest: Decimal = 0
        var totalPaid: Decimal = 0
        var pmiDropMonth: Int? = nil
        let startedAboveThreshold = pmiAppliesAtStart(input)

        // Hard cap: term + a safety margin. Extra payments only shorten the term.
        let maxIterations = min(n + 1, 601)
        let cal = Calendar.current
        var month = 0

        while balance > 0 && month < maxIterations {
            month += 1
            let interest = (balance * r).rounded(2)
            var principalPart = basePI - interest
            // Apply extra principal (recurring + a one-time bump on its month).
            var extraThisMonth = extra
            if month == oneTimeMonth { extraThisMonth += max(0, oneTimeExtra) }
            principalPart += extraThisMonth

            // Never overpay the remaining balance.
            if principalPart > balance { principalPart = balance }
            let paymentThisMonth = interest + principalPart
            balance = (balance - principalPart).rounded(2)
            if balance < 0 { balance = 0 }

            totalInterest += interest
            totalPaid += paymentThisMonth

            // Detect the PMI drop month (first month balance ≤ 78% LTV).
            if startedAboveThreshold, pmiDropMonth == nil, balance <= pmiThresholdBalance {
                pmiDropMonth = month
            }

            let date = cal.date(byAdding: .month, value: month, to: startDate) ?? startDate
            rows.append(AmortizationRow(
                id: month,
                date: date,
                payment: paymentThisMonth.rounded(2),
                interest: interest,
                principal: principalPart.rounded(2),
                extra: extraThisMonth.rounded(2),
                balance: balance
            ))
        }

        let payoffMonths = rows.count
        let payoffDate = rows.last?.date
            ?? cal.date(byAdding: .month, value: max(1, payoffMonths), to: startDate)
            ?? startDate

        return AmortizationResult(
            rows: rows,
            totalInterest: totalInterest.rounded(2),
            totalPaid: totalPaid.rounded(2),
            payoffDate: payoffDate,
            monthsToPayoff: payoffMonths,
            pmiDropMonth: pmiDropMonth
        )
    }

    // MARK: Extra-payment comparison

    struct ExtraPaymentImpact: Equatable {
        var baselineMonths: Int
        var acceleratedMonths: Int
        var monthsSaved: Int
        var baselineInterest: Decimal
        var acceleratedInterest: Decimal
        var interestSaved: Decimal
    }

    /// Compares the baseline schedule with one carrying extra principal.
    static func extraPaymentImpact(_ input: LoanInput,
                                   extraMonthly: Decimal,
                                   oneTimeExtra: Decimal = 0,
                                   oneTimeMonth: Int = 1) -> ExtraPaymentImpact {
        let baseline = amortize(input, extraMonthly: 0)
        let accelerated = amortize(input,
                                   extraMonthly: max(0, extraMonthly),
                                   oneTimeExtra: oneTimeExtra,
                                   oneTimeMonth: oneTimeMonth)
        return ExtraPaymentImpact(
            baselineMonths: baseline.monthsToPayoff,
            acceleratedMonths: accelerated.monthsToPayoff,
            monthsSaved: max(0, baseline.monthsToPayoff - accelerated.monthsToPayoff),
            baselineInterest: baseline.totalInterest,
            acceleratedInterest: accelerated.totalInterest,
            interestSaved: max(0, baseline.totalInterest - accelerated.totalInterest)
        )
    }

    /// The recurring extra that a biweekly (half-payment every 2 weeks) plan approximates:
    /// 26 half-payments = 13 monthly payments/yr ≈ one extra payment, spread monthly.
    static func biweeklyEquivalentExtra(_ input: LoanInput) -> Decimal {
        let pi = monthlyPI(principal: input.principal, annualRatePct: input.annualRatePct, months: input.months)
        return divide(pi, by: 12).rounded(2)   // one extra P&I per year, spread over 12 months
    }

    // MARK: Refinance compare

    /// Compares the current loan (remaining balance/rate/term) with a new loan.
    static func refinance(currentBalance: Decimal,
                          currentRatePct: Decimal,
                          currentRemainingMonths: Int,
                          newRatePct: Decimal,
                          newTermYears: Int,
                          closingCosts: Decimal) -> RefinanceResult {
        let curBal = max(0, currentBalance)
        let curMonths = max(1, currentRemainingMonths)
        let newMonths = max(1, newTermYears * 12)
        let costs = max(0, closingCosts)

        let curPI = monthlyPI(principal: curBal, annualRatePct: max(0, currentRatePct), months: curMonths)
        // New loan typically rolls closing costs into the financed balance? Keep it explicit:
        // we finance the same balance and pay closing costs separately for break-even clarity.
        let newPI = monthlyPI(principal: curBal, annualRatePct: max(0, newRatePct), months: newMonths)

        let savings = (curPI - newPI).rounded(2)
        let breakEven: Int?
        if savings > 0 {
            let monthsDec = divide(costs, by: savings)
            // Ceil the months: any partial month rounds up.
            breakEven = ceilToInt(monthsDec)
        } else {
            breakEven = nil
        }

        let curLifetime = (curPI * Decimal(curMonths) - curBal).rounded(2)
        let newLifetime = (newPI * Decimal(newMonths) - curBal).rounded(2)
        let delta = (newLifetime + costs - curLifetime).rounded(2)

        return RefinanceResult(
            currentPayment: curPI,
            newPayment: newPI,
            monthlySavings: savings,
            closingCosts: costs,
            breakEvenMonths: breakEven,
            currentLifetimeInterest: max(0, curLifetime),
            newLifetimeInterest: max(0, newLifetime),
            lifetimeInterestDelta: delta
        )
    }

    /// Smallest Int ≥ value (ceil) for a non-negative Decimal.
    static func ceilToInt(_ value: Decimal) -> Int {
        guard value > 0 else { return 0 }
        var up = Decimal()
        var v = value
        NSDecimalRound(&up, &v, 0, .up)
        return NSDecimalNumber(decimal: up).intValue
    }

    // MARK: Affordability

    /// Solves for the maximum affordable home price under front-/back-end DTI caps.
    /// All divisions guarded. Returns zeros when income is non-positive.
    static func affordability(grossMonthlyIncome: Decimal,
                              monthlyDebts: Decimal,
                              downPayment: Decimal,
                              annualRatePct: Decimal,
                              termYears: Int,
                              frontEndDTI: Decimal,
                              backEndDTI: Decimal,
                              propertyTaxPct: Decimal,
                              annualInsurance: Decimal,
                              monthlyHOA: Decimal) -> AffordabilityResult {
        let income = max(0, grossMonthlyIncome)
        let debts = max(0, monthlyDebts)
        let down = max(0, downPayment)
        let months = max(1, termYears * 12)
        guard income > 0 else {
            return AffordabilityResult(maxHomePrice: down, maxLoanAmount: 0, estimatedPayment: 0,
                                       principalAndInterest: 0, frontEndDTI: 0, backEndDTI: 0,
                                       bindingConstraint: "Income required")
        }

        // Budget for total housing payment (PITI) under each ratio.
        let frontBudget = income * frontEndDTI
        let backBudget = max(0, income * backEndDTI - debts)
        let housingBudget = max(0, min(frontBudget, backBudget))
        let binding = frontBudget <= backBudget ? "Front-end (28%)" : "Back-end (36%)"

        // PITI = P&I + tax + insurance + HOA. Tax scales with price; insurance & HOA are fixed here.
        // We solve for P (loan) such that PITI = housingBudget. Price = P + down.
        // taxMonthly = price·taxPct/12 = (P+down)·taxPct/12
        // P&I = P · factor, where factor = r(1+r)^n/((1+r)^n−1) (or 1/n if r==0).
        let insMonthly = monthlyInsurance(annualInsurance: annualInsurance)
        let hoaMonthly = max(0, monthlyHOA)
        let taxRateMonthly = divide(propertyTaxPct / 100, by: 12)   // fraction of price per month
        let piFactor = piFactorPerDollar(annualRatePct: annualRatePct, months: months)

        // housingBudget = P·piFactor + (P+down)·taxRateMonthly + insMonthly + hoaMonthly
        // => housingBudget − down·taxRateMonthly − insMonthly − hoaMonthly = P·(piFactor + taxRateMonthly)
        let available = housingBudget - down * taxRateMonthly - insMonthly - hoaMonthly
        let coefficient = piFactor + taxRateMonthly
        let maxLoan = coefficient > 0 ? max(0, divide(available, coefficient)).rounded(2) : 0
        let maxPrice = (maxLoan + down).rounded(2)

        let pi = (maxLoan * piFactor).rounded(2)
        let tax = (maxPrice * taxRateMonthly).rounded(2)
        let piti = (pi + tax + insMonthly + hoaMonthly).rounded(2)

        let front = income > 0 ? divide(piti, income) : 0
        let back = income > 0 ? divide(piti + debts, income) : 0

        return AffordabilityResult(
            maxHomePrice: maxPrice,
            maxLoanAmount: maxLoan,
            estimatedPayment: piti,
            principalAndInterest: pi,
            frontEndDTI: front,
            backEndDTI: back,
            bindingConstraint: binding
        )
    }

    /// The P&I per $1 of loan principal (the amortization factor). Guarded.
    static func piFactorPerDollar(annualRatePct: Decimal, months n: Int) -> Decimal {
        guard n > 0 else { return 0 }
        let r = divide(annualRatePct / 100, by: 12)
        if r == 0 { return divide(1, by: Decimal(n)) }
        let pow = power(1 + r, n)
        let denom = pow - 1
        guard denom != 0 else { return divide(1, by: Decimal(n)) }
        return divide(r * pow, by: denom)
    }
}
