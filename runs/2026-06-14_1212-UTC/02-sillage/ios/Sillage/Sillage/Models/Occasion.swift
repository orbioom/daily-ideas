import SwiftUI

/// An occasion a fragrance suits. Stored as a comma-joined set of rawValues.
enum Occasion: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case office = "Office"
    case evening = "Evening"
    case date = "Date"
    case formal = "Formal"
    case sport = "Sport"
    case leisure = "Leisure"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .daily: return "sun.and.horizon"
        case .office: return "briefcase"
        case .evening: return "moon.stars"
        case .date: return "heart"
        case .formal: return "suit.heart"
        case .sport: return "figure.run"
        case .leisure: return "beach.umbrella"
        }
    }
}
