import Foundation
import SwiftData

/// A scheduled alarm. Weekdays are stored as `[Int]` (1 = Sunday … 7 = Saturday, matching
/// `Calendar.component(.weekday:)`) because SwiftData can't persist a `Set<Int>` directly.
/// All numeric inputs are clamped in the initializer so a corrupt or out-of-range value can
/// never crash the scheduler or the UI.
@Model
final class Alarm {
    @Attribute(.unique) var id: UUID
    var hour: Int                 // 0...23
    var minute: Int               // 0...59
    var repeatDays: [Int]         // subset of 1...7 (Calendar weekday numbering)
    var label: String
    var soundName: String
    var missionTypeRaw: String
    var missionDifficultyRaw: String
    var missionReps: Int
    var snoozeEnabled: Bool
    var snoozeMinutes: Int
    var maxSnoozes: Int
    var volumeRampSeconds: Int
    var isEnabled: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         hour: Int = 7,
         minute: Int = 0,
         repeatDays: [Int] = [],
         label: String = "Wake up",
         soundName: String = SoundLibrary.defaultSoundName,
         missionType: MissionType = .math,
         missionDifficulty: MissionDifficulty = .medium,
         missionReps: Int = 3,
         snoozeEnabled: Bool = true,
         snoozeMinutes: Int = 9,
         maxSnoozes: Int = 3,
         volumeRampSeconds: Int = 20,
         isEnabled: Bool = true,
         createdAt: Date = Date()) {
        self.id = id
        self.hour = min(23, max(0, hour))
        self.minute = min(59, max(0, minute))
        self.repeatDays = Alarm.sanitize(repeatDays)
        self.label = label.isEmpty ? "Alarm" : label
        self.soundName = soundName
        self.missionTypeRaw = missionType.rawValue
        self.missionDifficultyRaw = missionDifficulty.rawValue
        self.missionReps = min(10, max(1, missionReps))
        self.snoozeEnabled = snoozeEnabled
        self.snoozeMinutes = min(30, max(1, snoozeMinutes))
        self.maxSnoozes = min(10, max(0, maxSnoozes))
        self.volumeRampSeconds = min(120, max(0, volumeRampSeconds))
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    // MARK: Typed accessors (raw-value enums are guarded with sensible fallbacks)

    var missionType: MissionType {
        get { MissionType(rawValue: missionTypeRaw) ?? .math }
        set { missionTypeRaw = newValue.rawValue }
    }

    var missionDifficulty: MissionDifficulty {
        get { MissionDifficulty(rawValue: missionDifficultyRaw) ?? .medium }
        set { missionDifficultyRaw = newValue.rawValue }
    }

    var repeatSet: Set<Int> {
        get { Set(repeatDays) }
        set { repeatDays = Alarm.sanitize(Array(newValue)) }
    }

    var isRepeating: Bool { !repeatDays.isEmpty }

    /// Keep only valid weekday numbers (1...7), unique and sorted.
    static func sanitize(_ days: [Int]) -> [Int] {
        Array(Set(days.filter { (1...7).contains($0) })).sorted()
    }
}
