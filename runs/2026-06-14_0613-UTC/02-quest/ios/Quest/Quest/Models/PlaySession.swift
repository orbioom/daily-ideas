import Foundation
import SwiftData

@Model
final class PlaySession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var hours: Double
    var note: String
    var game: Game?

    init(date: Date = .now, hours: Double, note: String = "") {
        self.id = UUID()
        self.date = date
        self.hours = max(0, hours)
        self.note = note
    }
}
