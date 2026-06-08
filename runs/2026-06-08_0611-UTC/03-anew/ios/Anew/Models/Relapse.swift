import Foundation
import SwiftData

@Model
final class Relapse {
    var id: UUID
    var date: Date
    var previousCleanDays: Int
    var note: String
    var quit: Quit?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        previousCleanDays: Int,
        note: String,
        quit: Quit? = nil
    ) {
        self.id = id
        self.date = date
        self.previousCleanDays = previousCleanDays
        self.note = note
        self.quit = quit
    }
}
