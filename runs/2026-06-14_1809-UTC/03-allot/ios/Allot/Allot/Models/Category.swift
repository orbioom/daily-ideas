import Foundation
import SwiftData
import SwiftUI

/// High-level grouping for budget categories.
enum CategoryGroup: String, CaseIterable, Identifiable, Codable {
    case billsAndUtilities
    case food
    case transportation
    case lifestyle
    case savingsGoals
    case debt
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .billsAndUtilities: return "Bills & Utilities"
        case .food: return "Food"
        case .transportation: return "Transportation"
        case .lifestyle: return "Lifestyle"
        case .savingsGoals: return "Savings Goals"
        case .debt: return "Debt"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .billsAndUtilities: return "bolt.fill"
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .lifestyle: return "sparkles"
        case .savingsGoals: return "target"
        case .debt: return "creditcard.fill"
        case .other: return "square.grid.2x2"
        }
    }

    /// Stable display order for the budget screen.
    var sortRank: Int {
        switch self {
        case .billsAndUtilities: return 0
        case .food: return 1
        case .transportation: return 2
        case .lifestyle: return 3
        case .savingsGoals: return 4
        case .debt: return 5
        case .other: return 6
        }
    }
}

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupRaw: String
    var emoji: String
    var rollover: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Allocation.category)
    var allocations: [Allocation]

    @Relationship(deleteRule: .nullify, inverse: \Transaction.categoryRef)
    var transactions: [Transaction]

    init(id: UUID = UUID(),
         name: String,
         group: CategoryGroup,
         emoji: String = "💸",
         rollover: Bool = true,
         sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.groupRaw = group.rawValue
        self.emoji = emoji
        self.rollover = rollover
        self.sortOrder = sortOrder
        self.allocations = []
        self.transactions = []
    }

    var group: CategoryGroup {
        get { CategoryGroup(rawValue: groupRaw) ?? .other }
        set { groupRaw = newValue.rawValue }
    }
}
