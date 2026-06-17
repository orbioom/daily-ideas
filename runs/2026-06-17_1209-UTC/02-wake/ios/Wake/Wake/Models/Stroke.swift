import SwiftUI

/// A swim stroke or set discipline. Stored on models as its rawValue String.
enum Stroke: String, CaseIterable, Identifiable, Codable {
    case freestyle
    case backstroke
    case breaststroke
    case butterfly
    case im            // individual medley
    case kick
    case drill
    case choice

    var id: String { rawValue }

    var label: String {
        switch self {
        case .freestyle: return "Freestyle"
        case .backstroke: return "Backstroke"
        case .breaststroke: return "Breaststroke"
        case .butterfly: return "Butterfly"
        case .im: return "IM"
        case .kick: return "Kick"
        case .drill: return "Drill"
        case .choice: return "Choice"
        }
    }

    var shortLabel: String {
        switch self {
        case .freestyle: return "Free"
        case .backstroke: return "Back"
        case .breaststroke: return "Breast"
        case .butterfly: return "Fly"
        case .im: return "IM"
        case .kick: return "Kick"
        case .drill: return "Drill"
        case .choice: return "Choice"
        }
    }

    var symbol: String {
        switch self {
        case .freestyle: return "figure.pool.swim"
        case .backstroke: return "arrow.up.and.person.rectangle.portrait"
        case .breaststroke: return "figure.open.water.swim"
        case .butterfly: return "wind"
        case .im: return "circle.hexagongrid"
        case .kick: return "figure.kickboxing"
        case .drill: return "scope"
        case .choice: return "questionmark.circle"
        }
    }

    /// A distinct hue per stroke for charts and badges.
    var hue: Color {
        switch self {
        case .freestyle: return Color(hex: 0x0E8C9C)
        case .backstroke: return Color(hex: 0x3F8FE0)
        case .breaststroke: return Color(hex: 0x2E8B6B)
        case .butterfly: return Color(hex: 0xC9772B)
        case .im: return Color(hex: 0x8255C8)
        case .kick: return Color(hex: 0xC0492F)
        case .drill: return Color(hex: 0x6B868D)
        case .choice: return Color(hex: 0x4A6068)
        }
    }

    /// MET value used for a rough calorie estimate (varies by stroke intensity).
    var baseMET: Double {
        switch self {
        case .freestyle: return 8.3
        case .backstroke: return 8.0
        case .breaststroke: return 10.3
        case .butterfly: return 13.8
        case .im: return 9.5
        case .kick: return 7.0
        case .drill: return 6.0
        case .choice: return 7.0
        }
    }

    static func from(_ raw: String) -> Stroke {
        Stroke(rawValue: raw) ?? .freestyle
    }
}
