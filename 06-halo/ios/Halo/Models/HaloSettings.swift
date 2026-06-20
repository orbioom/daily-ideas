import Foundation
import SwiftData

@Model
final class HaloSettings {
    var hasCompletedOnboarding: Bool
    var hasPro: Bool
    var headphonesReminderShown: Bool
    var defaultTimerMinutes: Int
    var ambientNoiseEnabled: Bool
    var ambientNoiseLevel: Float
    var backgroundAudioEnabled: Bool
    var userName: String

    init(
        hasCompletedOnboarding: Bool = false,
        hasPro: Bool = false,
        headphonesReminderShown: Bool = false,
        defaultTimerMinutes: Int = 20,
        ambientNoiseEnabled: Bool = false,
        ambientNoiseLevel: Float = 0.3,
        backgroundAudioEnabled: Bool = true,
        userName: String = ""
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPro = hasPro
        self.headphonesReminderShown = headphonesReminderShown
        self.defaultTimerMinutes = defaultTimerMinutes
        self.ambientNoiseEnabled = ambientNoiseEnabled
        self.ambientNoiseLevel = ambientNoiseLevel
        self.backgroundAudioEnabled = backgroundAudioEnabled
        self.userName = userName
    }

    static func fetchOrCreate(in context: ModelContext) -> HaloSettings {
        let descriptor = FetchDescriptor<HaloSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = HaloSettings()
        context.insert(settings)
        return settings
    }
}
