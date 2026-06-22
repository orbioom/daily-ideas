import Foundation
import SwiftData

@Model
final class MoonJournalEntry {
    var id: UUID
    var date: Date
    var content: String
    var moodRating: Int
    var moonPhaseRaw: String
    var illumination: Double
    var tags: [String]

    init(date: Date = .now, content: String = "", moodRating: Int = 3,
         moonPhaseRaw: String = "", illumination: Double = 0, tags: [String] = []) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.moodRating = moodRating
        self.moonPhaseRaw = moonPhaseRaw
        self.illumination = illumination
        self.tags = tags
    }

    var moonPhase: MoonPhase { MoonPhase(rawValue: moonPhaseRaw) ?? .newMoon }
}
