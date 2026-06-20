import Foundation
import SwiftData

enum LifeEventCategory: String, Codable, CaseIterable {
    case birth = "Birth"
    case death = "Death"
    case marriage = "Marriage"
    case divorce = "Divorce"
    case education = "Education"
    case career = "Career"
    case migration = "Migration"
    case military = "Military"
    case health = "Health"
    case achievement = "Achievement"
    case other = "Other"

    var icon: String {
        switch self {
        case .birth: return "star.circle.fill"
        case .death: return "moon.circle.fill"
        case .marriage: return "heart.circle.fill"
        case .divorce: return "xmark.circle.fill"
        case .education: return "book.circle.fill"
        case .career: return "briefcase.circle.fill"
        case .migration: return "map.circle.fill"
        case .military: return "shield.circle.fill"
        case .health: return "cross.circle.fill"
        case .achievement: return "trophy.circle.fill"
        case .other: return "circle.fill"
        }
    }

    var color: String {
        switch self {
        case .birth: return "systemYellow"
        case .death: return "systemIndigo"
        case .marriage: return "systemPink"
        case .divorce: return "systemOrange"
        case .education: return "systemBlue"
        case .career: return "systemGreen"
        case .migration: return "systemTeal"
        case .military: return "systemBrown"
        case .health: return "systemRed"
        case .achievement: return "systemPurple"
        case .other: return "systemGray"
        }
    }
}

@Model
final class LifeEvent {
    var id: UUID
    var title: String
    var category: LifeEventCategory
    var date: Date?
    var dateIsApproximate: Bool
    var location: String
    var description: String
    var person: Person?
    var createdAt: Date

    init(title: String, category: LifeEventCategory, person: Person) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.dateIsApproximate = false
        self.location = ""
        self.description = ""
        self.createdAt = Date()
        self.person = person
    }
}
