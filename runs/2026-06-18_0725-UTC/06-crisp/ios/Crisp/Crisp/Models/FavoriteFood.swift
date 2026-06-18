import Foundation
import SwiftData

/// A user-favorited catalog food, referenced by its stable catalog id.
@Model
final class FavoriteFood {
    @Attribute(.unique) var id: UUID
    var foodId: String
    var addedAt: Date

    init(id: UUID = UUID(), foodId: String, addedAt: Date = .now) {
        self.id = id
        self.foodId = foodId
        self.addedAt = addedAt
    }
}
