import Foundation
import SwiftData

@Model
final class SurgeSettings {
    var id: UUID
    var unit: String             // "km" or "mi"
    var hapticsEnabled: Bool
    var notificationsEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int

    init(
        id: UUID = UUID(),
        unit: String = "km",
        hapticsEnabled: Bool = true,
        notificationsEnabled: Bool = false,
        reminderHour: Int = 7,
        reminderMinute: Int = 0
    ) {
        self.id = id
        self.unit = unit
        self.hapticsEnabled = hapticsEnabled
        self.notificationsEnabled = notificationsEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    var useMetric: Bool {
        unit == "km"
    }
}
