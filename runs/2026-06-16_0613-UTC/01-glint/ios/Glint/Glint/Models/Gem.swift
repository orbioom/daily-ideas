import SwiftUI

/// The six jewel colors. Each has BOTH a distinct color AND a distinct SF Symbol
/// glyph so the game is fully playable for color-blind players.
enum GemColor: Int, CaseIterable, Codable, Identifiable, Hashable {
    case amethyst = 0   // violet
    case ruby           // red
    case citrine        // amber
    case emerald        // green
    case sapphire       // blue
    case topaz          // pink/magenta

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .amethyst: return "Amethyst"
        case .ruby: return "Ruby"
        case .citrine: return "Citrine"
        case .emerald: return "Emerald"
        case .sapphire: return "Sapphire"
        case .topaz: return "Topaz"
        }
    }

    /// Distinct color, readable in both light and dark mode.
    var color: Color {
        switch self {
        case .amethyst: return Color.dyn(0x8B5CF6, 0xA78BFA)
        case .ruby: return Color.dyn(0xE11D48, 0xFB7185)
        case .citrine: return Color.dyn(0xF59E0B, 0xFBBF24)
        case .emerald: return Color.dyn(0x059669, 0x34D399)
        case .sapphire: return Color.dyn(0x2563EB, 0x60A5FA)
        case .topaz: return Color.dyn(0xDB2777, 0xF472B6)
        }
    }

    /// Distinct SF Symbol glyph per color (color-blind friendly secondary cue).
    var symbol: String {
        switch self {
        case .amethyst: return "diamond.fill"
        case .ruby: return "heart.fill"
        case .citrine: return "sun.max.fill"
        case .emerald: return "leaf.fill"
        case .sapphire: return "drop.fill"
        case .topaz: return "star.fill"
        }
    }
}

/// A special power-up kind layered on top of a gem's color.
enum GemPower: Int, Codable, Hashable {
    case none = 0
    case striped       // clears its row or column when matched (from match-4)
    case colorBomb     // clears all gems of one color when matched (from match-5 line)

    var badgeSymbol: String? {
        switch self {
        case .none: return nil
        case .striped: return "bolt.fill"
        case .colorBomb: return "burst.fill"
        }
    }
}

/// A single board cell. `id` is stable per spawned gem so SwiftUI animations track
/// gems as they fall, rather than re-using positional identity.
struct Gem: Identifiable, Codable, Hashable {
    let id: UUID
    var color: GemColor
    var power: GemPower

    init(id: UUID = UUID(), color: GemColor, power: GemPower = .none) {
        self.id = id
        self.color = color
        self.power = power
    }

    var accessibilityLabel: String {
        switch power {
        case .none: return "\(color.name) gem"
        case .striped: return "striped \(color.name) gem"
        case .colorBomb: return "color bomb gem"
        }
    }
}
