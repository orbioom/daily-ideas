import SwiftUI

/// When a glucose reading was taken. Drives logbook placement and per-context averages.
enum ReadingContext: String, Codable, CaseIterable, Identifiable {
    case fasting = "Fasting"
    case beforeMeal = "Before meal"
    case afterMeal = "After meal"
    case bedtime = "Bedtime"
    case exercise = "Exercise"
    case random = "Random"

    var id: String { rawValue }

    var label: String { rawValue }

    var symbol: String {
        switch self {
        case .fasting: return "alarm"
        case .beforeMeal: return "fork.knife"
        case .afterMeal: return "clock.badge.checkmark"
        case .bedtime: return "moon.stars"
        case .exercise: return "figure.run"
        case .random: return "shuffle"
        }
    }

    /// Which logbook column this context maps into. `nil` falls into the "Other" bucket.
    var slot: MealSlot? {
        switch self {
        case .fasting: return .breakfast        // morning fasting reads sit with breakfast
        case .beforeMeal, .afterMeal: return nil // meal slot depends on time of day
        case .bedtime: return .bedtime
        case .exercise, .random: return nil
        }
    }
}
