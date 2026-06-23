import Foundation
import SwiftData

/// Singleton-style persisted preferences (a single row in SwiftData).
@Model
final class AppSettings {
    @Attribute(.unique) var id: String
    var hapticsEnabled: Bool
    var voiceCuesText: Bool        // show large text cues during sessions
    var keepScreenAwake: Bool
    var defaultSessionMinutes: Int // preferred session length
    var reminderEnabled: Bool
    /// Minutes since midnight for the daily reminder (e.g. 1260 = 21:00).
    var reminderMinuteOfDay: Int
    var favoritePatternIDs: [String]
    var preparationCountdown: Bool // 3-2-1 count-in before sessions

    init(id: String = "default",
         hapticsEnabled: Bool = true,
         voiceCuesText: Bool = true,
         keepScreenAwake: Bool = true,
         defaultSessionMinutes: Int = 5,
         reminderEnabled: Bool = false,
         reminderMinuteOfDay: Int = 21 * 60,
         favoritePatternIDs: [String] = ["box-4444", "coherent-55"],
         preparationCountdown: Bool = true) {
        self.id = id
        self.hapticsEnabled = hapticsEnabled
        self.voiceCuesText = voiceCuesText
        self.keepScreenAwake = keepScreenAwake
        self.defaultSessionMinutes = defaultSessionMinutes
        self.reminderEnabled = reminderEnabled
        self.reminderMinuteOfDay = reminderMinuteOfDay
        self.favoritePatternIDs = favoritePatternIDs
        self.preparationCountdown = preparationCountdown
    }

    func isFavorite(_ patternID: String) -> Bool {
        favoritePatternIDs.contains(patternID)
    }

    func toggleFavorite(_ patternID: String) {
        if let idx = favoritePatternIDs.firstIndex(of: patternID) {
            favoritePatternIDs.remove(at: idx)
        } else {
            favoritePatternIDs.append(patternID)
        }
    }

    var reminderHour: Int { (reminderMinuteOfDay / 60) % 24 }
    var reminderMinute: Int { reminderMinuteOfDay % 60 }
}
