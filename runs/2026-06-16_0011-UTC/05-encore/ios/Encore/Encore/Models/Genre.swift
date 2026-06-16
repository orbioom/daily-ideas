import SwiftUI
import SwiftData

/// A music genre tag. Many-to-many with `Concert` (the inverse lives here).
@Model
final class Genre {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorSeed: Int

    @Relationship(inverse: \Concert.genres)
    var concerts: [Concert] = []

    init(name: String, colorSeed: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorSeed = colorSeed
    }

    /// A stable hue derived from the stored seed, vivid in both modes.
    var hue: Color {
        let pair = Theme.ticketColors(seed: colorSeed)
        return pair.0
    }
}

/// The genres seeded by "Load sample data" and offered in the editor.
enum GenreCatalog {
    /// name → seed, kept stable so colours don't reshuffle.
    static let all: [(name: String, seed: Int)] = [
        ("Rock", 0), ("Pop", 1), ("Indie", 2), ("Hip-Hop", 3),
        ("Electronic", 4), ("Metal", 5), ("Jazz", 6), ("Folk", 7),
        ("R&B", 0), ("Punk", 1), ("Country", 2), ("Classical", 3),
        ("Alternative", 4), ("Soul", 5), ("Reggae", 6), ("Blues", 7)
    ]
}
