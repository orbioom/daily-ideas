import Foundation
import SwiftData

/// One of the four quarterly estimated-tax periods, with a mark-paid tracker.
@Model
final class EstimatedPayment {
    @Attribute(.unique) var id: UUID
    var year: Int
    var quarter: Int            // 1...4
    var dueDate: Date
    var amountDue: Double
    var amountPaid: Double
    var paid: Bool

    init(id: UUID = UUID(),
         year: Int,
         quarter: Int,
         dueDate: Date,
         amountDue: Double,
         amountPaid: Double = 0,
         paid: Bool = false) {
        self.id = id
        self.year = year
        self.quarter = quarter
        self.dueDate = dueDate
        self.amountDue = amountDue
        self.amountPaid = amountPaid
        self.paid = paid
    }

    var quarterLabel: String { "Q\(quarter)" }

    var remaining: Double { max(0, amountDue - amountPaid) }
}
