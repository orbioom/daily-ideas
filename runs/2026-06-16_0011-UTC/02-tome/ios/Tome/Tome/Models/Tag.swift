import Foundation
import SwiftData

/// A mood or genre label. Many-to-many with `Book` (the inverse lives here).
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorSeed: Int

    @Relationship(inverse: \Book.tags)
    var books: [Book] = []

    init(name: String, colorSeed: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorSeed = colorSeed
    }
}
