import SwiftUI

/// The six color tags a node can carry. Stored on `MapNode` as an `Int` (0...5).
enum NodePalette: Int, CaseIterable, Identifiable {
    case indigo = 0
    case teal
    case amber
    case rose
    case green
    case slate

    var id: Int { rawValue }

    /// Safe constructor that clamps out-of-range raw values to `.indigo`.
    static func from(_ raw: Int) -> NodePalette {
        NodePalette(rawValue: raw) ?? .indigo
    }

    var name: String {
        switch self {
        case .indigo: return "Indigo"
        case .teal:   return "Teal"
        case .amber:  return "Amber"
        case .rose:   return "Rose"
        case .green:  return "Green"
        case .slate:  return "Slate"
        }
    }

    /// Bubble fill color (dynamic for light/dark).
    var fill: Color {
        switch self {
        case .indigo: return Color.dyn(0xE7E7FC, 0x33335A)
        case .teal:   return Color.dyn(0xDDF3F1, 0x1E4744)
        case .amber:  return Color.dyn(0xFBEFD6, 0x4A3C1C)
        case .rose:   return Color.dyn(0xFBE2E8, 0x4A2530)
        case .green:  return Color.dyn(0xDDF1E4, 0x1F4430)
        case .slate:  return Color.dyn(0xE6E8EF, 0x32343F)
        }
    }

    /// Strong tone used for the bubble border / accent dot / connector.
    var accent: Color {
        switch self {
        case .indigo: return Color.dyn(0x5A5CD6, 0x9A9BF4)
        case .teal:   return Color.dyn(0x1F8C85, 0x57C9C0)
        case .amber:  return Color.dyn(0xB8841F, 0xE0AE54)
        case .rose:   return Color.dyn(0xC2476A, 0xEE89A6)
        case .green:  return Color.dyn(0x2F9E6B, 0x63CB98)
        case .slate:  return Color.dyn(0x5A5F70, 0x9AA0B2)
        }
    }

    /// Text color readable on `fill`.
    var ink: Color {
        switch self {
        case .indigo: return Color.dyn(0x2A2B66, 0xE9E9FF)
        case .teal:   return Color.dyn(0x123F3B, 0xDAF6F3)
        case .amber:  return Color.dyn(0x5A4310, 0xF7E9C9)
        case .rose:   return Color.dyn(0x5C1F30, 0xFBDCE4)
        case .green:  return Color.dyn(0x12492F, 0xD8F2E2)
        case .slate:  return Color.dyn(0x2A2D38, 0xE8EAF0)
        }
    }
}

/// Canvas themes that tint the backdrop and grid of the editor.
enum MapTheme: String, CaseIterable, Identifiable {
    case mist
    case dusk
    case meadow
    case slate

    var id: String { rawValue }

    /// Safe constructor.
    static func from(_ raw: String) -> MapTheme {
        MapTheme(rawValue: raw) ?? .mist
    }

    var name: String {
        switch self {
        case .mist:   return "Mist"
        case .dusk:   return "Dusk"
        case .meadow: return "Meadow"
        case .slate:  return "Slate"
        }
    }

    /// Whether this theme is part of the free tier (only 2 are free).
    var isFree: Bool {
        switch self {
        case .mist, .dusk: return true
        case .meadow, .slate: return false
        }
    }

    /// Canvas background.
    var canvas: Color {
        switch self {
        case .mist:   return Color.dyn(0xF1F1F8, 0x0E0E14)
        case .dusk:   return Color.dyn(0xEDE9F6, 0x14101E)
        case .meadow: return Color.dyn(0xEDF4ED, 0x0D140E)
        case .slate:  return Color.dyn(0xEDEFF3, 0x101216)
        }
    }

    /// Faint grid-dot color.
    var grid: Color {
        switch self {
        case .mist:   return Color.dyn(0xDDDDEC, 0x20202C)
        case .dusk:   return Color.dyn(0xDCD3EC, 0x261E36)
        case .meadow: return Color.dyn(0xD3E6D6, 0x18261B)
        case .slate:  return Color.dyn(0xD7DCE5, 0x1C2028)
        }
    }

    /// Small swatch shown in lists.
    var swatch: Color {
        switch self {
        case .mist:   return Color.dyn(0xB9B9E6, 0x6F6FB0)
        case .dusk:   return Color.dyn(0x8E76C9, 0x7A5EBD)
        case .meadow: return Color.dyn(0x6FB587, 0x4F9E6E)
        case .slate:  return Color.dyn(0x8A93A8, 0x657085)
        }
    }
}
