import Foundation
import SwiftData

enum RoomType: String, Codable, CaseIterable {
    case kitchen = "Kitchen"
    case bathroom = "Bathroom"
    case bedroom = "Bedroom"
    case livingRoom = "Living Room"
    case diningRoom = "Dining Room"
    case basement = "Basement"
    case attic = "Attic"
    case garage = "Garage"
    case exterior = "Exterior"
    case office = "Office"
    case laundry = "Laundry"
    case other = "Other"

    var icon: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .bathroom: return "drop.fill"
        case .bedroom: return "bed.double.fill"
        case .livingRoom: return "sofa.fill"
        case .diningRoom: return "table.furniture.fill"
        case .basement: return "arrow.down.to.line"
        case .attic: return "arrow.up.to.line"
        case .garage: return "car.fill"
        case .exterior: return "house.fill"
        case .office: return "desktopcomputer"
        case .laundry: return "washer.fill"
        case .other: return "square.grid.2x2"
        }
    }
}

enum ProjectStatus: String, Codable, CaseIterable {
    case planning = "Planning"
    case active = "Active"
    case paused = "Paused"
    case complete = "Complete"

    var icon: String {
        switch self {
        case .planning: return "pencil.circle"
        case .active: return "hammer.fill"
        case .paused: return "pause.circle.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

enum ProjectCategory: String, Codable, CaseIterable {
    case renovation = "Renovation"
    case repair = "Repair"
    case decoration = "Decoration"
    case addition = "Addition"
    case landscaping = "Landscaping"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case other = "Other"
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"
}

@Model
final class Property {
    var id: UUID
    var name: String
    var address: String
    var yearBuilt: Int
    var squareFootage: Int
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Room.property)
    var rooms: [Room]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.address = ""
        self.yearBuilt = 0
        self.squareFootage = 0
        self.notes = ""
        self.createdAt = Date()
        self.rooms = []
    }
}

@Model
final class Room {
    var id: UUID
    var name: String
    var type: RoomType
    var notes: String
    var property: Property?

    @Relationship(deleteRule: .cascade, inverse: \Project.room)
    var projects: [Project]

    init(name: String, type: RoomType, property: Property) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.notes = ""
        self.property = property
        self.projects = []
    }

    var activeProjectCount: Int { projects.filter { $0.status == .active }.count }
    var completedProjectCount: Int { projects.filter { $0.status == .complete }.count }
}

@Model
final class Project {
    var id: UUID
    var name: String
    var status: ProjectStatus
    var category: ProjectCategory
    var budget: Double
    var startDate: Date?
    var targetDate: Date?
    var completedDate: Date?
    var notes: String
    var room: Room?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ProjectTask.project)
    var tasks: [ProjectTask]

    @Relationship(deleteRule: .cascade, inverse: \Material.project)
    var materials: [Material]

    @Relationship(deleteRule: .cascade, inverse: \ProjectPhoto.project)
    var photos: [ProjectPhoto]

    init(name: String, status: ProjectStatus = .planning, room: Room) {
        self.id = UUID()
        self.name = name
        self.status = status
        self.category = .renovation
        self.budget = 0
        self.notes = ""
        self.room = room
        self.createdAt = Date()
        self.tasks = []
        self.materials = []
        self.photos = []
    }

    var actualCost: Double {
        materials.reduce(0) { $0 + ($1.unitCost * Double($1.quantity)) }
    }

    var budgetRemaining: Double { budget - actualCost }
    var budgetUsedFraction: Double {
        guard budget > 0 else { return 0 }
        return min(actualCost / budget, 1.0)
    }

    var taskCompletionFraction: Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter { $0.status == .done }.count
        return Double(done) / Double(tasks.count)
    }

    var unpurchasedMaterials: [Material] { materials.filter { !$0.purchased } }
}

@Model
final class ProjectTask {
    var id: UUID
    var title: String
    var status: TaskStatus
    var notes: String
    var dueDate: Date?
    var project: Project?
    var createdAt: Date

    init(title: String, project: Project) {
        self.id = UUID()
        self.title = title
        self.status = .todo
        self.notes = ""
        self.project = project
        self.createdAt = Date()
    }
}

@Model
final class Material {
    var id: UUID
    var name: String
    var quantity: Int
    var unit: String
    var unitCost: Double
    var purchased: Bool
    var vendor: String
    var notes: String
    var project: Project?
    var createdAt: Date

    init(name: String, quantity: Int = 1, unit: String = "unit", unitCost: Double = 0, project: Project) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.unitCost = unitCost
        self.purchased = false
        self.vendor = ""
        self.notes = ""
        self.project = project
        self.createdAt = Date()
    }

    var totalCost: Double { unitCost * Double(quantity) }
}

@Model
final class ProjectPhoto {
    var id: UUID
    var filename: String
    var caption: String
    var isAfterPhoto: Bool
    var dateTaken: Date
    var project: Project?

    init(filename: String, caption: String = "", isAfterPhoto: Bool = false, project: Project) {
        self.id = UUID()
        self.filename = filename
        self.caption = caption
        self.isAfterPhoto = isAfterPhoto
        self.dateTaken = Date()
        self.project = project
    }
}

@Model
final class ScaffoldSettings {
    var onboardingComplete: Bool
    var currencySymbol: String
    var showBudgetOnCards: Bool
    var defaultTaskView: Bool
    var enablePhotoReminders: Bool

    init() {
        self.onboardingComplete = false
        self.currencySymbol = "$"
        self.showBudgetOnCards = true
        self.defaultTaskView = true
        self.enablePhotoReminders = false
    }
}
