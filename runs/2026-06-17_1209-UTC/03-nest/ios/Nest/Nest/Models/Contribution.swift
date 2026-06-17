import Foundation
import SwiftData

@Model
final class Contribution {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Always stored as a positive magnitude; `isWithdrawal` decides the sign.
    var amount: Double
    var isWithdrawal: Bool
    var note: String

    var goal: Goal?

    init(date: Date = .now,
         amount: Double,
         isWithdrawal: Bool = false,
         note: String = "",
         goal: Goal? = nil) {
        self.id = UUID()
        self.date = date
        self.amount = abs(amount)
        self.isWithdrawal = isWithdrawal
        self.note = note
        self.goal = goal
    }

    /// Net effect on the goal balance (deposits add, withdrawals subtract).
    var signedAmount: Double {
        isWithdrawal ? -amount : amount
    }
}
