import Foundation
import SwiftData

/// A single scent note (e.g. "Bergamot") tagged with an olfactory family.
/// Shared across fragrances via the note-placement child records.
@Model
final class ScentNote {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored as raw string for SwiftData stability; access via `family`.
    var familyRaw: String
    /// True for the seeded library; user-added notes are false.
    var isSeeded: Bool

    /// Nullify (not cascade): deleting a note must not delete a fragrance's pyramid entry —
    /// the placement keeps its snapshot name/family. Only a fragrance cascade-owns placements.
    @Relationship(deleteRule: .nullify, inverse: \NotePlacement.note)
    var placements: [NotePlacement] = []

    init(name: String, family: NoteFamily, isSeeded: Bool = false) {
        self.id = UUID()
        self.name = name
        self.familyRaw = family.rawValue
        self.isSeeded = isSeeded
    }

    var family: NoteFamily {
        get { NoteFamily(rawValue: familyRaw) ?? .floral }
        set { familyRaw = newValue.rawValue }
    }
}
