import Foundation

/// One row of an amortization schedule.
struct AmortRow: Identifiable, Hashable {
    let month: Int          // 1-based payment number
    let date: Date          // date this payment is due
    let payment: Double      // total amount paid this month (P+I+extra, last row may be partial)
    let principal: Double    // portion applied to principal (excluding extra)
    let interest: Double     // portion that is interest
    let extra: Double        // extra principal applied this month
    let balance: Double      // remaining balance after this payment

    var id: Int { month }
}

/// Aggregate results for a loan, optionally vs a no-extra baseline.
struct LoanSummary: Hashable {
    var monthlyPayment: Double      // scheduled base payment (no extra)
    var totalPaid: Double           // sum of all payments incl. extra
    var totalInterest: Double       // sum of all interest
    var totalPrincipal: Double      // original principal repaid
    var payoffDate: Date            // date of the final payment
    var payoffMonths: Int           // number of payments to clear the loan
    var monthsSaved: Int            // vs baseline (>= 0)
    var interestSaved: Double       // vs baseline (>= 0)
}

/// Pure loan/mortgage math. No I/O, no rounding inside the calc — callers round
/// for display only. Every division is guarded; no force-unwraps.
enum LoanMath {

    /// Maximum iterations guard so a pathological input can never spin forever.
    private static func iterationCap(_ termMonths: Int) -> Int {
        max(2, termMonths) * 2 + 12
    }

    /// Scheduled monthly payment for a fully-amortizing loan.
    /// - Guards r == 0 (interest-free) → principal / n.
    static func monthlyPayment(principal: Double, annualRatePct: Double, termMonths: Int) -> Double {
        let n = max(1, termMonths)
        let p = max(0, principal)
        let r = annualRatePct / 100.0 / 12.0
        guard r > 0 else { return p / Double(n) }
        let denom = 1.0 - pow(1.0 + r, -Double(n))
        guard denom > 0 else { return p / Double(n) }
        return p * r / denom
    }

    /// Build the amortization schedule.
    /// - Applies `extraMonthly` every month, plus a one-time `extraOneTime`
    ///   payment at `extraOneTimeMonth` (1-based; ignored if <= 0 or amount <= 0).
    /// - Final row is the partial payment that lands the balance exactly at 0.
    static func schedule(principal: Double,
                         annualRatePct: Double,
                         termMonths: Int,
                         startDate: Date,
                         extraMonthly: Double = 0,
                         extraOneTime: Double = 0,
                         extraOneTimeMonth: Int = 0,
                         calendar: Calendar = .current) -> [AmortRow] {
        var rows: [AmortRow] = []
        let p = max(0, principal)
        guard p > 0 else { return rows }

        let n = max(1, termMonths)
        let r = annualRatePct / 100.0 / 12.0
        let basePayment = monthlyPayment(principal: p, annualRatePct: annualRatePct, termMonths: n)
        let safeExtraMonthly = max(0, extraMonthly)
        let safeOneTime = max(0, extraOneTime)

        var balance = p
        let cap = iterationCap(n)
        var month = 0

        while balance > 0.005 && month < cap {
            month += 1
            let interest = balance * r
            // Base principal portion of the scheduled payment.
            var principalPortion = basePayment - interest
            if principalPortion < 0 { principalPortion = 0 } // safety for tiny rates

            // Extra principal for this month.
            var extra = safeExtraMonthly
            if extraOneTimeMonth > 0, month == extraOneTimeMonth {
                extra += safeOneTime
            }

            var totalPrincipalThisMonth = principalPortion + extra

            // Never overpay: clamp to remaining balance.
            if totalPrincipalThisMonth >= balance {
                totalPrincipalThisMonth = balance
                // Re-split: pay down whatever scheduled principal we can first,
                // then the rest counts as extra.
                if principalPortion > totalPrincipalThisMonth {
                    principalPortion = totalPrincipalThisMonth
                    extra = 0
                } else {
                    extra = totalPrincipalThisMonth - principalPortion
                }
            }

            let newBalance = max(0, balance - totalPrincipalThisMonth)
            let payment = interest + totalPrincipalThisMonth

            let date = calendar.date(byAdding: .month, value: month, to: startDate) ?? startDate

            rows.append(AmortRow(month: month,
                                 date: date,
                                 payment: payment,
                                 principal: principalPortion,
                                 interest: interest,
                                 extra: extra,
                                 balance: newBalance))
            balance = newBalance
        }

        return rows
    }

    /// Summarize a schedule vs an optional baseline (no-extra) schedule.
    static func summarize(principal: Double,
                          annualRatePct: Double,
                          termMonths: Int,
                          startDate: Date,
                          extraMonthly: Double = 0,
                          extraOneTime: Double = 0,
                          extraOneTimeMonth: Int = 0,
                          calendar: Calendar = .current) -> LoanSummary {
        let basePayment = monthlyPayment(principal: principal, annualRatePct: annualRatePct, termMonths: termMonths)

        let withExtra = schedule(principal: principal,
                                 annualRatePct: annualRatePct,
                                 termMonths: termMonths,
                                 startDate: startDate,
                                 extraMonthly: extraMonthly,
                                 extraOneTime: extraOneTime,
                                 extraOneTimeMonth: extraOneTimeMonth,
                                 calendar: calendar)

        let baseline = schedule(principal: principal,
                                annualRatePct: annualRatePct,
                                termMonths: termMonths,
                                startDate: startDate,
                                extraMonthly: 0,
                                extraOneTime: 0,
                                extraOneTimeMonth: 0,
                                calendar: calendar)

        let totalPaid = withExtra.reduce(0) { $0 + $1.payment }
        let totalInterest = withExtra.reduce(0) { $0 + $1.interest }
        let payoffMonths = withExtra.count
        let payoffDate = withExtra.last?.date
            ?? (calendar.date(byAdding: .month, value: max(1, termMonths), to: startDate) ?? startDate)

        let baselineInterest = baseline.reduce(0) { $0 + $1.interest }
        let baselineMonths = baseline.count

        let monthsSaved = max(0, baselineMonths - payoffMonths)
        let interestSaved = max(0, baselineInterest - totalInterest)

        return LoanSummary(monthlyPayment: basePayment,
                           totalPaid: totalPaid,
                           totalInterest: totalInterest,
                           totalPrincipal: max(0, principal),
                           payoffDate: payoffDate,
                           payoffMonths: payoffMonths,
                           monthsSaved: monthsSaved,
                           interestSaved: interestSaved)
    }

    /// Inverse / affordability: largest principal financeable for a monthly budget.
    /// - Guards r == 0 → budget * n.
    static func maxPrincipal(monthlyBudget: Double, annualRatePct: Double, termMonths: Int) -> Double {
        let n = max(1, termMonths)
        let budget = max(0, monthlyBudget)
        let r = annualRatePct / 100.0 / 12.0
        guard r > 0 else { return budget * Double(n) }
        return budget * (1.0 - pow(1.0 + r, -Double(n))) / r
    }

    /// Refinance comparison result.
    struct Refi: Hashable {
        var currentPayment: Double
        var newPayment: Double
        var monthlyDiff: Double          // current - new (positive = saving per month)
        var currentLifetimeInterest: Double
        var newLifetimeInterest: Double
        var lifetimeInterestDiff: Double // current - new (positive = saving)
        var breakEvenMonths: Int?        // nil when there is no monthly saving
        var closingCosts: Double
    }

    /// Compare staying on the current loan vs refinancing.
    /// - `currentBalance` at `currentRate` over `remainingMonths`
    ///   vs `newRate` over `newTermMonths` + `closingCosts`.
    static func refinance(currentBalance: Double,
                          currentRatePct: Double,
                          remainingMonths: Int,
                          newRatePct: Double,
                          newTermMonths: Int,
                          closingCosts: Double) -> Refi {
        let bal = max(0, currentBalance)
        let curRemaining = max(1, remainingMonths)
        let newTerm = max(1, newTermMonths)
        let costs = max(0, closingCosts)

        let curPayment = monthlyPayment(principal: bal, annualRatePct: currentRatePct, termMonths: curRemaining)
        let newPayment = monthlyPayment(principal: bal, annualRatePct: newRatePct, termMonths: newTerm)

        let curInterest = max(0, curPayment * Double(curRemaining) - bal)
        let newInterest = max(0, newPayment * Double(newTerm) - bal)

        let monthlyDiff = curPayment - newPayment
        let lifetimeDiff = (curInterest) - (newInterest + costs)

        var breakEven: Int? = nil
        if monthlyDiff > 0 {
            breakEven = Int(ceil(costs / monthlyDiff))
        }

        return Refi(currentPayment: curPayment,
                    newPayment: newPayment,
                    monthlyDiff: monthlyDiff,
                    currentLifetimeInterest: curInterest,
                    newLifetimeInterest: newInterest,
                    lifetimeInterestDiff: lifetimeDiff,
                    breakEvenMonths: breakEven,
                    closingCosts: costs)
    }
}
