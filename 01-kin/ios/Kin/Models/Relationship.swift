import Foundation
import SwiftData

enum RelationshipType: String, Codable, CaseIterable {
    case parentChild = "Parent of"
    case childParent = "Child of"
    case spouse = "Spouse of"
    case sibling = "Sibling of"
    case other = "Related to"

    var inverseLabel: String {
        switch self {
        case .parentChild: return "Child of"
        case .childParent: return "Parent of"
        case .spouse: return "Spouse of"
        case .sibling: return "Sibling of"
        case .other: return "Related to"
        }
    }

    var icon: String {
        switch self {
        case .parentChild: return "arrow.down.circle"
        case .childParent: return "arrow.up.circle"
        case .spouse: return "heart.circle"
        case .sibling: return "person.2.circle"
        case .other: return "link.circle"
        }
    }
}

@Model
final class Relationship {
    var id: UUID
    var type: RelationshipType
    var notes: String
    var startDate: Date?
    var endDate: Date?
    var person1: Person?
    var person2: Person?
    var createdAt: Date

    init(type: RelationshipType, person1: Person, person2: Person) {
        self.id = UUID()
        self.type = type
        self.notes = ""
        self.createdAt = Date()
        self.person1 = person1
        self.person2 = person2
    }
}
