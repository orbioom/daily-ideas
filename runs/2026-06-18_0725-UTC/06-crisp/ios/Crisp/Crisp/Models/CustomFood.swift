import Foundation
import SwiftData

/// A user-authored food with its own temp/time. Counts against the free cap.
@Model
final class CustomFood {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var tempF: Int
    var minutes: Int
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        categoryRaw: String,
        tempF: Int,
        minutes: Int,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = categoryRaw
        self.tempF = min(max(tempF, 150), 450)
        self.minutes = min(max(minutes, 1), 180)
        self.notes = notes
        self.createdAt = createdAt
    }

    var category: FoodCategory {
        FoodCategory(rawValue: categoryRaw) ?? .snacks
    }
}
