import Foundation
import SwiftData

@Model
final class HaloSession {
    var id: UUID
    var date: Date
    var presetID: String
    var presetName: String
    var category: String
    var durationSeconds: Double
    var moodBefore: Int
    var moodAfter: Int
    var notes: String
    var completed: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        presetID: String,
        presetName: String,
        category: String,
        durationSeconds: Double,
        moodBefore: Int = 3,
        moodAfter: Int = 3,
        notes: String = "",
        completed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.presetID = presetID
        self.presetName = presetName
        self.category = category
        self.durationSeconds = durationSeconds
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.notes = notes
        self.completed = completed
    }

    var durationDisplay: String {
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        }
        return "\(seconds)s"
    }

    var moodDelta: Int { moodAfter - moodBefore }

    var moodDeltaSymbol: String {
        if moodDelta > 0 { return "↑" }
        if moodDelta < 0 { return "↓" }
        return "→"
    }

    var moodDeltaColor: String {
        if moodDelta > 0 { return "green" }
        if moodDelta < 0 { return "red" }
        return "gray"
    }

    var brainwaveCategory: BrainwaveCategory? {
        BrainwaveCategory(rawValue: category)
    }
}
