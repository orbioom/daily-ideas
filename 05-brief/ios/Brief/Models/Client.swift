import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var address: String
    var company: String
    var notes: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var invoices: [Invoice]

    init(
        name: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        company: String = "",
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.company = company
        self.notes = notes
        self.createdAt = .now
        self.invoices = []
    }

    var totalBilled: Decimal {
        invoices.reduce(Decimal(0)) { $0 + $1.total }
    }

    var totalPaid: Decimal {
        invoices.filter { $0.status == .paid }.reduce(Decimal(0)) { $0 + $1.total }
    }

    var outstanding: Decimal { totalBilled - totalPaid }
}
