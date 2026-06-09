import Foundation
import SwiftData

/// A person you want to stay close to. Owns interactions and important dates.
@Model
final class Person {
    var name: String
    var relationshipRaw: String
    var colorRaw: String
    var cadenceDays: Int          // desired reach-out interval; 0 = no reminder
    var howWeMet: String
    var notes: String
    var isFavorite: Bool
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Interaction.person)
    var interactions: [Interaction] = []
    @Relationship(deleteRule: .cascade, inverse: \ImportantDate.person)
    var dates: [ImportantDate] = []

    init(name: String,
         relationship: Relationship = .friend,
         color: PersonColor = .teal,
         cadenceDays: Int = 0,
         howWeMet: String = "",
         notes: String = "") {
        self.name = name
        self.relationshipRaw = relationship.rawValue
        self.colorRaw = color.rawValue
        self.cadenceDays = max(0, cadenceDays)
        self.howWeMet = howWeMet
        self.notes = notes
        self.isFavorite = false
        self.isArchived = false
        self.createdAt = .now
    }

    var relationship: Relationship {
        get { Relationship(rawValue: relationshipRaw) ?? .friend }
        set { relationshipRaw = newValue.rawValue }
    }
    var color: PersonColor {
        get { PersonColor(rawValue: colorRaw) ?? .teal }
        set { colorRaw = newValue.rawValue }
    }

    var lastContact: Date? { interactions.map(\.date).max() }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

/// A logged touchpoint with a person.
@Model
final class Interaction {
    var date: Date
    var typeRaw: String
    var note: String
    var person: Person?

    init(date: Date = .now, type: InteractionType = .text, note: String = "") {
        self.date = date
        self.typeRaw = type.rawValue
        self.note = note
    }

    var type: InteractionType {
        get { InteractionType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}

/// A date worth remembering for a person (birthday, anniversary, custom).
@Model
final class ImportantDate {
    var title: String
    var date: Date
    var kindRaw: String
    var recursAnnually: Bool
    var person: Person?

    init(title: String, date: Date, kind: DateKind = .birthday, recursAnnually: Bool = true) {
        self.title = title
        self.date = date
        self.kindRaw = kind.rawValue
        self.recursAnnually = recursAnnually
    }

    var kind: DateKind {
        get { DateKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }
}
