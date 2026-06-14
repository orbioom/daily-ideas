import Foundation
import SwiftData

@Model
final class Visit {
    @Attribute(.unique) var id: UUID
    var date: Date
    var note: String
    var companions: String
    var amountSpent: Double?
    var restaurant: Restaurant?

    init(date: Date = .now,
         note: String = "",
         companions: String = "",
         amountSpent: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.note = note
        self.companions = companions
        self.amountSpent = amountSpent
    }
}
