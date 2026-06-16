import Foundation
import SwiftData

/// A user-defined label (e.g. "Comfort watch", "Oscar winners") attached to many Titles.
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorSeed: Int
    /// Many-to-many; the inverse lives on `Title.tags`.
    var titles: [Title] = []

    init(name: String, colorSeed: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorSeed = colorSeed
        self.titles = []
    }
}
