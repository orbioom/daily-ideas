import Foundation
import SwiftData
import SwiftUI

enum InvoiceStatus: String, CaseIterable, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"

    var systemImage: String {
        switch self {
        case .draft: return "doc.text"
        case .sent: return "paperplane.fill"
        case .paid: return "checkmark.seal.fill"
        case .overdue: return "exclamationmark.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .draft: return "gray"
        case .sent: return "blue"
        case .paid: return "green"
        case .overdue: return "red"
        }
    }
}

@Model
final class Invoice {
    var id: UUID
    var number: String
    var issueDate: Date
    var dueDate: Date
    var status: InvoiceStatus
    var notes: String
    var taxRate: Decimal
    var discountAmount: Decimal
    var currencyCode: String
    var client: Client?
    @Relationship(deleteRule: .cascade) var lineItems: [LineItem]

    init(
        number: String = "",
        issueDate: Date = .now,
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    ) {
        self.id = UUID()
        self.number = number
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.status = .draft
        self.notes = ""
        self.taxRate = Decimal(0)
        self.discountAmount = Decimal(0)
        self.currencyCode = "USD"
        self.lineItems = []
    }

    var subtotal: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.subtotal }
    }

    var taxAmount: Decimal {
        (subtotal - discountAmount) * taxRate
    }

    var total: Decimal {
        max(Decimal(0), subtotal - discountAmount + taxAmount)
    }

    var isOverdue: Bool {
        status == .sent && dueDate < Date()
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var displayStatus: InvoiceStatus {
        if isOverdue { return .overdue }
        return status
    }
}
