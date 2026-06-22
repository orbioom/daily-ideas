import Foundation
import SwiftData

@Model
final class NourishSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var notificationsEnabled: Bool
    var primaryGoal: String
    var hapticsEnabled: Bool
    var windowHoursForCorrelation: Double
    var reminderHour: Int
    var reminderMinute: Int

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        notificationsEnabled: Bool = true,
        primaryGoal: String = "elimination",
        hapticsEnabled: Bool = true,
        windowHoursForCorrelation: Double = 24.0,
        reminderHour: Int = 20,
        reminderMinute: Int = 0
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.notificationsEnabled = notificationsEnabled
        self.primaryGoal = primaryGoal
        self.hapticsEnabled = hapticsEnabled
        self.windowHoursForCorrelation = windowHoursForCorrelation
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }
}

// MARK: - PrimaryGoal

enum PrimaryGoal: String, CaseIterable, Identifiable {
    case elimination = "elimination"
    case general = "general"
    case challenge = "challenge"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .elimination: return "Elimination Diet"
        case .general: return "General Food Tracking"
        case .challenge: return "Food Challenge Phase"
        }
    }

    var description: String {
        switch self {
        case .elimination:
            return "Remove top allergens for 3+ weeks to reset your baseline."
        case .general:
            return "Track meals and symptoms without a strict protocol."
        case .challenge:
            return "Reintroduce foods one at a time to identify triggers."
        }
    }

    var icon: String {
        switch self {
        case .elimination: return "minus.circle.fill"
        case .general: return "book.fill"
        case .challenge: return "flask.fill"
        }
    }
}

// MARK: - CorrelationWindow

enum CorrelationWindow: Double, CaseIterable, Identifiable {
    case twelve = 12.0
    case twentyFour = 24.0
    case fortyEight = 48.0

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .twelve: return "12 hours"
        case .twentyFour: return "24 hours"
        case .fortyEight: return "48 hours"
        }
    }
}
