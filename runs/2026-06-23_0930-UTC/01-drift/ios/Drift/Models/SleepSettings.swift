import Foundation
import SwiftData

/// Singleton-style settings record persisted via SwiftData. Holds the user's
/// chronotype, sleep goal and schedule anchors plus feature preferences.
@Model
final class SleepSettings {
    @Attribute(.unique) var id: UUID
    var chronotypeRaw: String
    /// Personal nightly sleep goal in hours (overrides chronotype default).
    var goalHours: Double
    /// The wake time the user is anchoring their schedule to.
    var anchorWakeTime: Date
    /// Preferences
    var hapticsEnabled: Bool
    var use24HourClock: Bool
    /// Whether the bedtime suggestion accounts for the wind-down lead time.
    var includeWindDownInSuggestion: Bool

    init(
        id: UUID = UUID(),
        chronotype: Chronotype = .bear,
        goalHours: Double = 8.0,
        anchorWakeTime: Date = SleepSettings.defaultWake(),
        hapticsEnabled: Bool = true,
        use24HourClock: Bool = false,
        includeWindDownInSuggestion: Bool = true
    ) {
        self.id = id
        self.chronotypeRaw = chronotype.rawValue
        self.goalHours = goalHours
        self.anchorWakeTime = anchorWakeTime
        self.hapticsEnabled = hapticsEnabled
        self.use24HourClock = use24HourClock
        self.includeWindDownInSuggestion = includeWindDownInSuggestion
    }

    var chronotype: Chronotype {
        get { Chronotype(rawValue: chronotypeRaw) ?? .bear }
        set { chronotypeRaw = newValue.rawValue }
    }

    static func defaultWake() -> Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    }
}
