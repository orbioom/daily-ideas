import Foundation
import SwiftData

/// A recorded payment that settles debt: `fromMember` paid `toMember` `amount`.
/// Reduces the payer's debt and the receiver's credit in the balance engine.
@Model
final class Settlement {
    var id: UUID
    var amount: Decimal
    var date: Date
    var note: String

    var group: SplitGroup?

    @Relationship var fromMember: Member?
    @Relationship var toMember: Member?

    init(id: UUID = UUID(),
         amount: Decimal,
         date: Date = .now,
         note: String = "",
         fromMember: Member? = nil,
         toMember: Member? = nil) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.fromMember = fromMember
        self.toMember = toMember
    }
}
