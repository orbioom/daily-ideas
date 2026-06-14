import SwiftUI

/// A season a fragrance suits. Stored as a comma-joined set of rawValues.
enum Season: String, Codable, CaseIterable, Identifiable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "wind"
        case .winter: return "snowflake"
        }
    }

    var hue: Color {
        switch self {
        case .spring: return Color.dyn(0x6FA84B, 0x97C977)
        case .summer: return Color.dyn(0xD7A019, 0xE8C24E)
        case .fall: return Color.dyn(0xB5612A, 0xD78F58)
        case .winter: return Color.dyn(0x4F7FA8, 0x82AAD0)
        }
    }

    /// The season for a given date (northern-hemisphere convention).
    static func current(for date: Date = .now) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
}
