import SwiftUI

/// Intended effort level for a set. Stored as rawValue String.
enum Effort: String, CaseIterable, Identifiable, Codable {
    case easy
    case moderate
    case hard
    case race

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .race: return "Race"
        }
    }

    var symbol: String {
        switch self {
        case .easy: return "tortoise.fill"
        case .moderate: return "figure.walk"
        case .hard: return "flame.fill"
        case .race: return "bolt.fill"
        }
    }

    var hue: Color {
        switch self {
        case .easy: return Color(hex: 0x2E8B6B)
        case .moderate: return Color(hex: 0x0E8C9C)
        case .hard: return Color(hex: 0xC9772B)
        case .race: return Color(hex: 0xC0492F)
        }
    }

    /// Multiplier applied to a stroke's base MET for calorie estimates.
    var metMultiplier: Double {
        switch self {
        case .easy: return 0.8
        case .moderate: return 1.0
        case .hard: return 1.2
        case .race: return 1.4
        }
    }

    static func from(_ raw: String) -> Effort {
        Effort(rawValue: raw) ?? .moderate
    }
}
