import Foundation
import SwiftData

/// A song = an ordered chain of sections, each pointing at a pattern with a
/// repeat count. Sections are owned by the song and deleted with it.
@Model
final class Song {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SongSection.song)
    var sections: [SongSection]

    init(name: String, createdAt: Date = .now, sections: [SongSection] = []) {
        self.name = name
        self.createdAt = createdAt
        self.sections = sections
    }

    /// Sections in their intended play order.
    var orderedSections: [SongSection] {
        sections.sorted { $0.order < $1.order }
    }

    var totalBars: Int {
        orderedSections.reduce(0) { $0 + max(1, $1.repeatCount) }
    }
}

@Model
final class SongSection {
    var order: Int
    var patternID: PersistentIdentifier
    var patternName: String     // denormalized for display & resilience
    var repeatCount: Int
    var song: Song?

    init(order: Int, patternID: PersistentIdentifier, patternName: String, repeatCount: Int = 1) {
        self.order = order
        self.patternID = patternID
        self.patternName = patternName
        self.repeatCount = max(1, repeatCount)
    }
}
