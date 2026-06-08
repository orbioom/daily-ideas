import Foundation
import SwiftData

@Model
final class CheckIn {
    var id: UUID
    var date: Date
    var mood: Int
    var note: String
    var pledged: Bool
    var quit: Quit?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Int,
        note: String,
        pledged: Bool = false,
        quit: Quit? = nil
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.note = note
        self.pledged = pledged
        self.quit = quit
    }
}
