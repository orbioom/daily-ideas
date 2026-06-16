import Foundation
import SwiftData

@Model
final class SubstitutionEntry {
    @Attribute(.unique) var id: UUID
    var ingredient: String
    var note: String
    /// True for user-authored entries (Pro feature).
    var isCustom: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SubstituteOption.entry)
    var options: [SubstituteOption]

    init(
        id: UUID = UUID(),
        ingredient: String,
        note: String = "",
        isCustom: Bool = false,
        createdAt: Date = .now,
        options: [SubstituteOption] = []
    ) {
        self.id = id
        self.ingredient = ingredient
        self.note = note
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.options = options
    }

    var orderedOptions: [SubstituteOption] {
        options.sorted { $0.sortOrder < $1.sortOrder }
    }
}

@Model
final class SubstituteOption {
    @Attribute(.unique) var id: UUID
    var text: String
    var ratioNote: String
    var sortOrder: Int

    var entry: SubstitutionEntry?

    init(
        id: UUID = UUID(),
        text: String,
        ratioNote: String = "",
        sortOrder: Int
    ) {
        self.id = id
        self.text = text
        self.ratioNote = ratioNote
        self.sortOrder = sortOrder
    }
}
