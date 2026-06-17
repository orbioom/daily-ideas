import SwiftUI

/// The overall character of a workout template. Stored as rawValue String.
enum WorkoutType: String, CaseIterable, Identifiable, Codable {
    case technique
    case endurance
    case sprint
    case mixed
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .technique: return "Technique"
        case .endurance: return "Endurance"
        case .sprint: return "Sprint"
        case .mixed: return "Mixed"
        case .custom: return "Custom"
        }
    }

    var symbol: String {
        switch self {
        case .technique: return "scope"
        case .endurance: return "infinity"
        case .sprint: return "bolt.fill"
        case .mixed: return "circle.hexagongrid.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var hue: Color {
        switch self {
        case .technique: return Color(hex: 0x6B868D)
        case .endurance: return Color(hex: 0x0E8C9C)
        case .sprint: return Color(hex: 0xC0492F)
        case .mixed: return Color(hex: 0x8255C8)
        case .custom: return Color(hex: 0x2E8B6B)
        }
    }

    static func from(_ raw: String) -> WorkoutType {
        WorkoutType(rawValue: raw) ?? .custom
    }
}
