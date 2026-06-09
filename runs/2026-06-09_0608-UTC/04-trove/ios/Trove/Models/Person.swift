import Foundation
import SwiftData

/// A person you give gifts to. Owns their gifts via a cascade relationship, so
/// deleting a person cleans up their ideas too.
@Model
final class Person {
    var name: String
    var relation: String        // Family / Friend / Partner / Colleague / Other
    var notes: String
    var birthday: Date?
    var sizesNote: String       // free-text clothing / shoe sizes
    var createdAt: Date
    var sortIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \Gift.person)
    var gifts: [Gift] = []

    init(name: String,
         relation: String = "Friend",
         notes: String = "",
         birthday: Date? = nil,
         sizesNote: String = "",
         sortIndex: Int = 0) {
        self.name = name
        self.relation = relation
        self.notes = notes
        self.birthday = birthday
        self.sizesNote = sizesNote
        self.sortIndex = sortIndex
        self.createdAt = .now
    }
}

/// The relations offered in pickers. Stored as plain strings on `Person` so the
/// schema stays simple, but surfaced as a typed list for UI.
enum Relation: String, CaseIterable, Identifiable {
    case family = "Family"
    case friend = "Friend"
    case partner = "Partner"
    case colleague = "Colleague"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .family: return "house"
        case .friend: return "person.2"
        case .partner: return "heart"
        case .colleague: return "briefcase"
        case .other: return "person"
        }
    }
}
