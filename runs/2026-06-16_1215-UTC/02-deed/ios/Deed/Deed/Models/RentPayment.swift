import SwiftUI
import SwiftData

@Model
final class RentPayment {
    @Attribute(.unique) var id: UUID
    var dueDate: Date
    var amountDue: Decimal
    var amountPaid: Decimal
    var paidDate: Date?
    var statusRaw: String

    var lease: Lease?

    init(
        id: UUID = UUID(),
        dueDate: Date,
        amountDue: Decimal,
        amountPaid: Decimal = 0,
        paidDate: Date? = nil,
        status: RentStatus = .unpaid
    ) {
        self.id = id
        self.dueDate = dueDate
        self.amountDue = amountDue
        self.amountPaid = amountPaid
        self.paidDate = paidDate
        self.statusRaw = status.rawValue
    }

    var status: RentStatus {
        get { RentStatus(rawValue: statusRaw) ?? .unpaid }
        set { statusRaw = newValue.rawValue }
    }

    var outstanding: Decimal {
        let diff = amountDue - amountPaid
        return diff > 0 ? diff : 0
    }

    /// Recompute status from amounts vs today.
    func reclassify(asOf today: Date = Date()) {
        if amountPaid >= amountDue && amountDue > 0 {
            status = .paid
            if paidDate == nil { paidDate = today }
        } else if amountPaid > 0 {
            status = .partial
        } else if dueDate < today {
            status = .late
        } else {
            status = .unpaid
        }
    }
}
