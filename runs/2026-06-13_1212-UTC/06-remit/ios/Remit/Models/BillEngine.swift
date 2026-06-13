import Foundation
import SwiftData

/// The status of a bill relative to today.
enum BillStatus {
    case paidThisPeriod
    case overdue
    case dueSoon
    case upcoming

    var label: String {
        switch self {
        case .paidThisPeriod: return "Paid"
        case .overdue:        return "Overdue"
        case .dueSoon:        return "Due soon"
        case .upcoming:       return "Upcoming"
        }
    }
}

/// A single projected bill occurrence on a specific calendar day.
struct BillOccurrence: Identifiable {
    let id = UUID()
    let date: Date
    let bill: Bill
    var amount: Decimal { bill.amount }
}

/// Pure, crash-proof money + date math for bills. Every Calendar operation and
/// division is guarded; due-date arithmetic is month-end-safe (a bill anchored
/// to the 31st resolves to the last day of shorter months).
enum BillEngine {

    // MARK: - Next due date (month-end-safe)

    /// The next due date strictly after `referenceDate`, starting from `dueDate`
    /// and stepping by `recurrence`. For `oneTime`, returns `dueDate` unchanged.
    static func nextDueDate(after referenceDate: Date, dueDate: Date, recurrence: Recurrence) -> Date {
        guard recurrence != .oneTime else { return dueDate }

        // If the anchor is already in the future, it is the next occurrence.
        if dueDate > referenceDate { return dueDate }

        // Step forward until we pass the reference date. Bounded to avoid any
        // pathological loop; in practice a handful of iterations.
        var candidate = dueDate
        var guardCount = 0
        let maxSteps = 5000
        while candidate <= referenceDate && guardCount < maxSteps {
            candidate = advance(candidate, by: recurrence, from: dueDate, steps: guardCount + 1)
            guardCount += 1
        }
        return candidate
    }

    /// Advances `anchor` forward by `steps` periods. Month/quarter/year stepping
    /// is computed from the original anchor's day so month-end clamping never
    /// drifts (e.g. Jan 31 → Feb 28 → Mar 31, not Feb 28 → Mar 28).
    private static func advance(_ current: Date, by recurrence: Recurrence, from anchor: Date, steps: Int) -> Date {
        let cal = Calendar.current
        switch recurrence {
        case .oneTime:
            return anchor
        case .weekly:
            return cal.date(byAdding: .day, value: 7 * steps, to: anchor) ?? current
        case .biweekly:
            return cal.date(byAdding: .day, value: 14 * steps, to: anchor) ?? current
        case .monthly:
            return clampedDate(addingMonths: steps, to: anchor) ?? current
        case .quarterly:
            return clampedDate(addingMonths: 3 * steps, to: anchor) ?? current
        case .yearly:
            return clampedDate(addingMonths: 12 * steps, to: anchor) ?? current
        }
    }

    /// Adds whole months to a date while clamping the day to the target month's
    /// length (so the 31st becomes the 30th/28th where needed).
    private static func clampedDate(addingMonths months: Int, to date: Date) -> Date? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let day = comps.day else { return nil }

        // Find the target year/month by adding months to the first of the month.
        var base = DateComponents()
        base.year = comps.year
        base.month = comps.month
        base.day = 1
        guard let firstOfMonth = cal.date(from: base),
              let targetMonthStart = cal.date(byAdding: .month, value: months, to: firstOfMonth) else {
            return nil
        }
        // Clamp the day to the target month's range.
        guard let range = cal.range(of: .day, in: .month, for: targetMonthStart) else { return nil }
        let clampedDay = min(day, range.upperBound - 1)

        var target = cal.dateComponents([.year, .month], from: targetMonthStart)
        target.day = clampedDay
        target.hour = comps.hour
        target.minute = comps.minute
        return cal.date(from: target)
    }

    // MARK: - Days until due

    /// Whole calendar days from today (start of day) until the bill's due date.
    /// Negative when overdue, 0 when due today.
    static func daysUntilDue(_ bill: Bill, today: Date = .now) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: today)
        let due = cal.startOfDay(for: bill.dueDate)
        return cal.dateComponents([.day], from: start, to: due).day ?? 0
    }

    // MARK: - Current-period window

    /// The [start, end) window of the bill's current period, ending at the next
    /// due date. A payment in this window means the bill is paid for the period.
    static func currentPeriodWindow(for bill: Bill, today: Date = .now) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let end = bill.dueDate
        let start: Date
        switch bill.recurrence {
        case .oneTime:
            // A one-time bill's "period" is simply everything up to its due date.
            start = bill.createdAt < end ? bill.createdAt : cal.date(byAdding: .day, value: -365, to: end) ?? end
        case .weekly:
            start = cal.date(byAdding: .day, value: -7, to: end) ?? end
        case .biweekly:
            start = cal.date(byAdding: .day, value: -14, to: end) ?? end
        case .monthly:
            start = clampedDate(addingMonths: -1, to: end) ?? end
        case .quarterly:
            start = clampedDate(addingMonths: -3, to: end) ?? end
        case .yearly:
            start = clampedDate(addingMonths: -12, to: end) ?? end
        }
        return (start, end)
    }

    /// Whether the bill is settled for the obligation the user currently sees.
    ///
    /// `markPaid` advances `dueDate` and records each payment's `dueDateSnapshot`
    /// (the due date it settled). A bill counts as paid-this-period when its
    /// latest payment settled a due date on or after the start of the current
    /// period — *and* that settled date hasn't yet passed relative to `today`.
    /// The time bound means a rolled-forward bill stops reading "paid" once its
    /// settled cycle is in the past and the next cycle is genuinely owed.
    static func isPaidThisPeriod(_ bill: Bill, today: Date = .now) -> Bool {
        guard bill.recurrence != .oneTime else {
            // One-time bills don't roll: any payment settles them for good.
            return bill.latestPayment != nil
        }
        guard let latest = bill.latestPayment else { return false }
        let cal = Calendar.current
        let window = currentPeriodWindow(for: bill, today: today)
        let prevDue = cal.startOfDay(for: window.start)
        let snapshot = cal.startOfDay(for: latest.dueDateSnapshot)
        let todayStart = cal.startOfDay(for: today)
        // Settled this period (snapshot is within the current window) and the
        // cycle it settled is still current (its due date is today or later).
        return snapshot >= prevDue && snapshot >= todayStart
    }

    // MARK: - Status

    static func status(_ bill: Bill, today: Date = .now) -> BillStatus {
        if isPaidThisPeriod(bill, today: today) { return .paidThisPeriod }
        let days = daysUntilDue(bill, today: today)
        if days < 0 { return .overdue }
        if days <= max(0, bill.dueSoonDays) { return .dueSoon }
        return .upcoming
    }

    // MARK: - Monthly equivalent

    /// Normalises any recurrence to an equivalent monthly cost. One-time bills
    /// contribute 0 to the recurring monthly obligation total.
    static func monthlyEquivalent(_ bill: Bill) -> Decimal {
        let perYear = bill.recurrence.occurrencesPerYear
        guard perYear > 0 else { return 0 }
        // amount * occurrencesPerYear / 12, done in Decimal.
        let yearly = bill.amount * Decimal(perYear)
        return yearly / 12
    }

    // MARK: - Mark paid

    /// Records a payment for the bill's current due date and advances the anchor
    /// to the next period (one-time bills stay put — they are simply paid).
    @discardableResult
    static func markPaid(_ bill: Bill, on date: Date = .now, amount: Decimal? = nil, context: ModelContext) -> Payment {
        let paidAmount = amount ?? bill.amount
        let payment = Payment(date: date,
                              amount: paidAmount,
                              billNameSnapshot: bill.name,
                              dueDateSnapshot: bill.dueDate,
                              bill: bill)
        context.insert(payment)
        bill.payments.append(payment)

        if bill.recurrence != .oneTime {
            // Advance to the next due date strictly after the one just paid.
            bill.dueDate = nextDueDate(after: bill.dueDate, dueDate: bill.dueDate, recurrence: bill.recurrence)
        }
        try? context.save()
        return payment
    }

    // MARK: - Upcoming projection

    /// Expands recurrences into concrete occurrences over `days` from `today`.
    /// Sorted ascending by date. Bounded per bill to stay crash-proof.
    static func upcomingOccurrences(_ bills: [Bill], today: Date = .now, days: Int = 60) -> [BillOccurrence] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: today)
        guard let horizon = cal.date(byAdding: .day, value: max(1, days), to: start) else { return [] }

        var result: [BillOccurrence] = []
        for bill in bills {
            if bill.recurrence == .oneTime {
                if bill.dueDate >= start && bill.dueDate <= horizon {
                    result.append(BillOccurrence(date: bill.dueDate, bill: bill))
                }
                continue
            }
            // Walk forward from the anchor, bounded.
            var cursor = bill.dueDate
            // If the anchor is in the past, jump to the next future occurrence.
            if cursor < start {
                cursor = nextDueDate(after: start, dueDate: bill.dueDate, recurrence: bill.recurrence)
            }
            var guardCount = 0
            while cursor <= horizon && guardCount < 400 {
                if cursor >= start {
                    result.append(BillOccurrence(date: cursor, bill: bill))
                }
                cursor = nextDueDate(after: cursor, dueDate: bill.dueDate, recurrence: bill.recurrence)
                guardCount += 1
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    /// Occurrences falling within the calendar month containing `month`.
    static func occurrences(in month: Date, bills: [Bill]) -> [BillOccurrence] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let dayCount = (cal.dateComponents([.day], from: interval.start, to: interval.end).day ?? 31) + 2
        let all = upcomingOccurrences(bills, today: interval.start, days: max(31, dayCount))
        return all.filter { $0.date >= interval.start && $0.date < interval.end }
    }
}
