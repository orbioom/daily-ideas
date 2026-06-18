import Foundation
import SwiftData

/// A record of something the user cooked — powers the Cook Log / Stats screen.
@Model
final class CookLog {
    @Attribute(.unique) var id: UUID
    var foodId: String?
    var name: String
    var date: Date
    var tempF: Int
    var minutes: Int
    /// 1...5 stars. 0 means "unrated".
    var rating: Int
    var note: String

    init(
        id: UUID = UUID(),
        foodId: String? = nil,
        name: String,
        date: Date = .now,
        tempF: Int,
        minutes: Int,
        rating: Int = 0,
        note: String = ""
    ) {
        self.id = id
        self.foodId = foodId
        self.name = name
        self.date = date
        self.tempF = tempF
        self.minutes = max(0, minutes)
        self.rating = min(max(rating, 0), 5)
        self.note = note
    }
}
