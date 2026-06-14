import Foundation
import SwiftData

/// Joins a `ScentNote` to a `Fragrance` at a pyramid slot (top / heart / base).
/// Cascade-owned by the fragrance; many of these reference one shared note.
@Model
final class NotePlacement {
    @Attribute(.unique) var id: UUID
    /// Stored as raw string; access via `slot`.
    var slotRaw: String
    /// Snapshot of the note name + family so a deleted note never breaks display/stats.
    var noteName: String
    var familyRaw: String
    /// Ordering within a slot (so the pyramid reads in the author's order).
    var order: Int

    var fragrance: Fragrance?
    var note: ScentNote?

    init(slot: NoteSlot, note: ScentNote, order: Int = 0) {
        self.id = UUID()
        self.slotRaw = slot.rawValue
        self.noteName = note.name
        self.familyRaw = note.family.rawValue
        self.order = order
        self.note = note
    }

    var slot: NoteSlot {
        get { NoteSlot(rawValue: slotRaw) ?? .top }
        set { slotRaw = newValue.rawValue }
    }

    /// Family derived from the live note when present, else the snapshot.
    var family: NoteFamily {
        if let note { return note.family }
        return NoteFamily(rawValue: familyRaw) ?? .floral
    }

    /// Name derived from the live note when present, else the snapshot.
    var displayName: String {
        note?.name ?? noteName
    }
}
