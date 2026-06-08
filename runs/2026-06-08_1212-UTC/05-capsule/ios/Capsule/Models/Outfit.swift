import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID
    var name: String
    var notes: String
    var favorite: Bool
    var createdAt: Date

    var items: [ClothingItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        favorite: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.favorite = favorite
        self.createdAt = createdAt
    }

    var totalValue: Double { items.reduce(0) { $0 + $1.cost } }
}
