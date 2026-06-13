import Foundation
import SwiftData

/// A recurring (or one-time) bill the user must pay. `dueDate` is the anchor:
/// the next date this bill is due. Marking it paid advances `dueDate` forward
/// by one period and appends a `Payment`.
@Model
final class Bill {
    var name: String
    var amount: Decimal
    var categoryRaw: String
    /// The next due date (the anchor). Advances when marked paid.
    var dueDate: Date
    var recurrenceRaw: String
    var autopay: Bool
    var notes: String
    /// How many days ahead counts as "due soon" for this bill.
    var dueSoonDays: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Payment.bill)
    var payments: [Payment]

    init(name: String,
         amount: Decimal,
         category: Category,
         dueDate: Date,
         recurrence: Recurrence,
         autopay: Bool = false,
         notes: String = "",
         dueSoonDays: Int = 3,
         createdAt: Date = .now) {
        self.name = name
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.dueDate = dueDate
        self.recurrenceRaw = recurrence.rawValue
        self.autopay = autopay
        self.notes = notes
        self.dueSoonDays = max(0, dueSoonDays)
        self.createdAt = createdAt
        self.payments = []
    }

    var category: Category { Category(rawValue: categoryRaw) ?? .other }
    var recurrence: Recurrence { Recurrence(rawValue: recurrenceRaw) ?? .monthly }

    /// The most recent payment by date, if any.
    var latestPayment: Payment? {
        payments.max { $0.date < $1.date }
    }
}

/// A single recorded payment against a bill. Carries a name snapshot so the
/// payment history survives deletion of its parent bill.
@Model
final class Payment {
    var date: Date
    var amount: Decimal
    var billNameSnapshot: String
    /// The due date this payment was settling — lets us judge on-time vs late.
    var dueDateSnapshot: Date
    var bill: Bill?

    init(date: Date,
         amount: Decimal,
         billNameSnapshot: String,
         dueDateSnapshot: Date,
         bill: Bill? = nil) {
        self.date = date
        self.amount = amount
        self.billNameSnapshot = billNameSnapshot
        self.dueDateSnapshot = dueDateSnapshot
        self.bill = bill
    }

    /// Paid on or before the due date it was settling.
    var wasOnTime: Bool {
        let cal = Calendar.current
        let paid = cal.startOfDay(for: date)
        let due = cal.startOfDay(for: dueDateSnapshot)
        return paid <= due
    }
}
