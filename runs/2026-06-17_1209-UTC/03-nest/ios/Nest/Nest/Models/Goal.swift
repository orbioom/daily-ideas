import Foundation
import SwiftData

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    /// Target amount, persisted as Double; convert to Decimal for display math.
    var targetAmount: Double
    var targetDate: Date?
    var startDate: Date
    /// 1 = highest priority.
    var priority: Int
    /// Stored as raw string for SwiftData stability; access via `category`.
    var categoryRaw: String
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Contribution.goal)
    var contributions: [Contribution]

    init(name: String,
         symbolName: String,
         colorHex: String,
         targetAmount: Double,
         targetDate: Date? = nil,
         startDate: Date = .now,
         priority: Int = 2,
         category: GoalCategory = .other,
         isArchived: Bool = false,
         createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.targetAmount = max(0, targetAmount)
        self.targetDate = targetDate
        self.startDate = startDate
        self.priority = min(max(priority, 1), 3)
        self.categoryRaw = category.rawValue
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.contributions = []
    }

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var priorityLabel: String {
        switch priority {
        case 1: return "High"
        case 2: return "Normal"
        default: return "Low"
        }
    }
}
