import Foundation
import SwiftData

enum TaskCategory: String, CaseIterable, Codable {
    case work = "Work"
    case study = "Study"
    case creative = "Creative"
    case personal = "Personal"
    case health = "Health"
    case chores = "Chores"
    case other = "Other"

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .study: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .chores: return "house.fill"
        case .other: return "circle.fill"
        }
    }

    var color: String {
        switch self {
        case .work: return "blue"
        case .study: return "purple"
        case .creative: return "orange"
        case .personal: return "green"
        case .health: return "red"
        case .chores: return "brown"
        case .other: return "gray"
        }
    }
}

@Model
final class FocusTask {
    var id: UUID
    var title: String
    var category: TaskCategory
    var estimatedMinutes: Int
    var isCompleted: Bool
    var completedDate: Date?
    var sortIndex: Int
    var note: String

    init(
        title: String,
        category: TaskCategory = .work,
        estimatedMinutes: Int = 25,
        sortIndex: Int = 0,
        note: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.isCompleted = false
        self.completedDate = nil
        self.sortIndex = sortIndex
        self.note = note
    }
}

@Model
final class FocusSession {
    var id: UUID
    var date: Date
    var taskTitle: String
    var plannedMinutes: Int
    var actualMinutes: Int
    var wasCompleted: Bool
    var category: TaskCategory

    init(
        taskTitle: String,
        plannedMinutes: Int,
        actualMinutes: Int,
        wasCompleted: Bool,
        category: TaskCategory
    ) {
        self.id = UUID()
        self.date = Date()
        self.taskTitle = taskTitle
        self.plannedMinutes = plannedMinutes
        self.actualMinutes = actualMinutes
        self.wasCompleted = wasCompleted
        self.category = category
    }
}
