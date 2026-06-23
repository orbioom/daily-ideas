import SwiftUI

/// Chronotype model loosely inspired by Michael Breus' sleep-animal framing.
/// Each chronotype shifts the *ideal* bedtime relative to a person's wake time.
enum Chronotype: String, Codable, CaseIterable, Identifiable {
    case lion      // early riser, peaks in the morning
    case bear      // tracks the sun, the most common type
    case wolf      // night owl, struggles with early mornings
    case dolphin   // light, restless sleeper

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lion: return "Lion"
        case .bear: return "Bear"
        case .wolf: return "Wolf"
        case .dolphin: return "Dolphin"
        }
    }

    var symbol: String {
        switch self {
        case .lion: return "sun.max.fill"
        case .bear: return "sun.haze.fill"
        case .wolf: return "moon.stars.fill"
        case .dolphin: return "moon.zzz.fill"
        }
    }

    var blurb: String {
        switch self {
        case .lion:
            return "You wake naturally before dawn and fade early in the evening. Mornings are your peak."
        case .bear:
            return "Your clock follows the sun. You do best with a steady, conventional schedule."
        case .wolf:
            return "You come alive at night and dread early alarms. Later is genuinely better for you."
        case .dolphin:
            return "You sleep lightly and wake easily. A protected wind-down matters most for you."
        }
    }

    /// Suggested night-sleep target in hours for this chronotype.
    var targetSleepHours: Double {
        switch self {
        case .lion: return 7.5
        case .bear: return 8.0
        case .wolf: return 8.0
        case .dolphin: return 7.0
        }
    }

    /// How long before lights-out the wind-down should begin, in minutes.
    var windDownMinutes: Int {
        switch self {
        case .lion: return 30
        case .bear: return 45
        case .wolf: return 60
        case .dolphin: return 75
        }
    }

    /// Tint used to color the chronotype across the UI.
    var tint: Color {
        switch self {
        case .lion: return Theme.dawn
        case .bear: return Theme.good
        case .wolf: return Theme.dusk
        case .dolphin: return Theme.night
        }
    }
}
