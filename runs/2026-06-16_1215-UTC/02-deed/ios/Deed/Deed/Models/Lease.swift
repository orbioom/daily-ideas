import SwiftUI
import SwiftData

@Model
final class Lease {
    @Attribute(.unique) var id: UUID
    var tenantName: String
    var tenantEmail: String
    var tenantPhone: String
    var startDate: Date
    var endDate: Date?
    var monthlyRent: Decimal
    var deposit: Decimal
    /// Day of month rent is due (1...28).
    var rentDueDay: Int
    var isActive: Bool
    var notes: String
    var createdAt: Date

    var unit: Unit?

    @Relationship(deleteRule: .cascade, inverse: \RentPayment.lease)
    var payments: [RentPayment]

    init(
        id: UUID = UUID(),
        tenantName: String,
        tenantEmail: String = "",
        tenantPhone: String = "",
        startDate: Date,
        endDate: Date? = nil,
        monthlyRent: Decimal,
        deposit: Decimal,
        rentDueDay: Int,
        isActive: Bool = true,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tenantName = tenantName
        self.tenantEmail = tenantEmail
        self.tenantPhone = tenantPhone
        self.startDate = startDate
        self.endDate = endDate
        self.monthlyRent = monthlyRent
        self.deposit = deposit
        self.rentDueDay = min(max(rentDueDay, 1), 28)
        self.isActive = isActive
        self.notes = notes
        self.createdAt = createdAt
        self.payments = []
    }
}
