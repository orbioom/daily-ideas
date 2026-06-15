import Foundation
import SwiftData

/// The single active life profile. Drives the whole grid: birth date and life expectancy.
@Model
final class LifeProfile {
    @Attribute(.unique) var id: UUID
    var name: String?
    var birthDate: Date
    /// Clamped to a sane range on write (see `SpanEngine.clampExpectancy`).
    var lifeExpectancyYears: Int
    var weekStartsMonday: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String? = nil,
         birthDate: Date,
         lifeExpectancyYears: Int = 90,
         weekStartsMonday: Bool = true,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.lifeExpectancyYears = SpanEngine.clampExpectancy(lifeExpectancyYears)
        self.weekStartsMonday = weekStartsMonday
        self.createdAt = createdAt
    }
}
