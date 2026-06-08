import Foundation
import SwiftData

/// A reusable label applied to entries (many-to-many with JournalEntry).
@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: UInt32
    var createdAt: Date
    var entries: [JournalEntry] = []

    init(id: UUID = UUID(), name: String, colorHex: UInt32 = 0x5E63A6, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
