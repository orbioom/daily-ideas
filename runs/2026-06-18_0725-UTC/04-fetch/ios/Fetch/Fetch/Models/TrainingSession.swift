import Foundation
import SwiftData

@Model
final class TrainingSession {
    @Attribute(.unique) var id: UUID
    var dog: Dog?
    var trickId: String
    var date: Date
    var durationSec: Int
    var reps: Int
    /// Success rating 1...5 (how well it went).
    var successRating: Int
    var note: String

    init(
        id: UUID = UUID(),
        dog: Dog? = nil,
        trickId: String,
        date: Date = Date(),
        durationSec: Int = 0,
        reps: Int = 0,
        successRating: Int = 3,
        note: String = ""
    ) {
        self.id = id
        self.dog = dog
        self.trickId = trickId
        self.date = date
        self.durationSec = max(0, durationSec)
        self.reps = max(0, reps)
        self.successRating = min(5, max(1, successRating))
        self.note = note
    }
}
