import SwiftData
import SwiftUI
import Foundation

enum BoardCategory: String, CaseIterable, Codable {
    case career      = "Career"
    case health      = "Health"
    case lifestyle   = "Lifestyle"
    case love        = "Love"
    case travel      = "Travel"
    case finances    = "Finances"
    case creativity  = "Creativity"
    case personal    = "Personal"

    var icon: String {
        switch self {
        case .career:     return "briefcase.fill"
        case .health:     return "heart.fill"
        case .lifestyle:  return "sun.max.fill"
        case .love:       return "heart.circle.fill"
        case .travel:     return "airplane"
        case .finances:   return "dollarsign.circle.fill"
        case .creativity: return "paintbrush.fill"
        case .personal:   return "person.fill"
        }
    }

    var accentHex: String {
        switch self {
        case .career:     return "#5C7CFA"
        case .health:     return "#FF6B6B"
        case .lifestyle:  return "#FCC419"
        case .love:       return "#FF8CC8"
        case .travel:     return "#20C997"
        case .finances:   return "#51CF66"
        case .creativity: return "#CC5DE8"
        case .personal:   return "#74C0FC"
        }
    }
}

@Model
class VisionBoard {
    var id: UUID
    var title: String
    var categoryRaw: String
    var affirmation: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade) var items: [BoardItem] = []

    var category: BoardCategory {
        BoardCategory(rawValue: categoryRaw) ?? .personal
    }

    init(title: String, category: BoardCategory, affirmation: String = "") {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.affirmation = affirmation
        self.createdAt = Date()
        self.sortOrder = 0
    }
}

@Model
class BoardItem {
    var id: UUID
    var imageFilename: String?   // FileManager filename
    var caption: String
    var sortIndex: Int

    var board: VisionBoard?

    init(imageFilename: String? = nil, caption: String = "", sortIndex: Int = 0) {
        self.id = UUID()
        self.imageFilename = imageFilename
        self.caption = caption
        self.sortIndex = sortIndex
    }
}

@Model
class Goal {
    var id: UUID
    var title: String
    var categoryRaw: String
    var targetDate: Date?
    var notes: String
    var isCompleted: Bool
    var completedDate: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var milestones: [Milestone] = []

    var category: BoardCategory {
        BoardCategory(rawValue: categoryRaw) ?? .personal
    }

    var progress: Double {
        guard !milestones.isEmpty else { return isCompleted ? 1 : 0 }
        let done = milestones.filter(\.isCompleted).count
        return Double(done) / Double(milestones.count)
    }

    init(title: String, category: BoardCategory, targetDate: Date? = nil, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.targetDate = targetDate
        self.notes = notes
        self.isCompleted = false
        self.createdAt = Date()
    }
}

@Model
class Milestone {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedDate: Date?
    var sortIndex: Int

    var goal: Goal?

    init(title: String, sortIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.sortIndex = sortIndex
    }
}
