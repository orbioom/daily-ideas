import Foundation
import SwiftData

@Model
final class SurfSettings {
    var id: UUID = UUID()
    var showOnboarding: Bool = true
    var useMetricHeight: Bool = false
    var useMetricWind: Bool = false
    var hapticsEnabled: Bool = true
    var defaultDurationMinutes: Int = 90
    var reminderEnabled: Bool = false
    var reminderHour: Int = 7
    var reminderMinute: Int = 0
    var isProUnlocked: Bool = false

    init() {
        self.id = UUID()
    }
}
