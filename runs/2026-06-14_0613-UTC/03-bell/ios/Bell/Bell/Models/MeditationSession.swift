import Foundation
import SwiftData

@Model
final class MeditationSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Seconds actually sat.
    var durationSec: Int
    var presetName: String
    /// Raw value of `Mood`.
    var moodRaw: String
    var note: String
    var completedFully: Bool

    init(id: UUID = UUID(),
         date: Date,
         durationSec: Int,
         presetName: String,
         mood: Mood,
         note: String,
         completedFully: Bool) {
        self.id = id
        self.date = date
        self.durationSec = durationSec
        self.presetName = presetName
        self.moodRaw = mood.rawValue
        self.note = note
        self.completedFully = completedFully
    }

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .calm }
        set { moodRaw = newValue.rawValue }
    }

    var durationMin: Int { durationSec / 60 }

    var durationLabel: String {
        let m = durationSec / 60
        let s = durationSec % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m) min" }
        return "\(m)m \(s)s"
    }

    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        return TimeOfDay.from(hour: hour)
    }
}
