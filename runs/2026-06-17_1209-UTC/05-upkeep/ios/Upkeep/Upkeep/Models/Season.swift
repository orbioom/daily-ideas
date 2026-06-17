import SwiftUI

/// A calendar season. Persisted as its raw String value.
enum Season: String, CaseIterable, Codable, Identifiable {
    case spring
    case summer
    case fall
    case winter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .winter: return "Winter"
        }
    }

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
        case .spring: return Color(hex: 0x5CB874)
        case .summer: return Color(hex: 0xE0A93C)
        case .fall: return Color(hex: 0xC8612E)
        case .winter: return Color(hex: 0x4C8BC4)
        }
    }

    /// The month (1...12) on which this season starts in the northern hemisphere.
    var northernStartMonth: Int {
        switch self {
        case .spring: return 3
        case .summer: return 6
        case .fall: return 9
        case .winter: return 12
        }
    }
}
