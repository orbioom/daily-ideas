import Foundation
import SwiftData

@Model
final class CrescentSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var hapticsEnabled: Bool

    init() {
        self.id = UUID()
        self.hasCompletedOnboarding = false
        self.reminderEnabled = false
        self.reminderHour = 20
        self.reminderMinute = 0
        self.hapticsEnabled = true
    }
}
