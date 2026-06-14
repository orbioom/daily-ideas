import Foundation
import SwiftData

/// Kind of account. Credit cards are liabilities (negative balances are owed).
enum AccountType: String, CaseIterable, Identifiable, Codable {
    case checking
    case savings
    case cash
    case creditCard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .cash: return "Cash"
        case .creditCard: return "Credit Card"
        }
    }

    var symbol: String {
        switch self {
        case .checking: return "building.columns"
        case .savings: return "banknote"
        case .cash: return "dollarsign.circle"
        case .creditCard: return "creditcard"
        }
    }

    /// Credit cards are liabilities; their stored balance represents what is owed.
    var isLiability: Bool { self == .creditCard }
}

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var onBudget: Bool
    var startingBalance: Double
    var dateAdded: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.accountRef)
    var transactions: [Transaction]

    init(id: UUID = UUID(),
         name: String,
         type: AccountType,
         onBudget: Bool = true,
         startingBalance: Double = 0,
         dateAdded: Date = .now) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.onBudget = onBudget
        self.startingBalance = startingBalance
        self.dateAdded = dateAdded
        self.transactions = []
    }

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .checking }
        set { typeRaw = newValue.rawValue }
    }
}
