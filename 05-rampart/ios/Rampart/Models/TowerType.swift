import SwiftUI

enum TowerType: String, CaseIterable, Identifiable {
    case archer = "Archer"
    case cannon = "Cannon"
    case frost = "Frost"

    var id: String { rawValue }

    var cost: Int {
        switch self {
        case .archer: return 50
        case .cannon: return 100
        case .frost: return 75
        }
    }

    var damage: Double {
        switch self {
        case .archer: return 10
        case .cannon: return 40
        case .frost: return 5
        }
    }

    /// Range in game-space units (320x480 logical coordinate space)
    var range: Double {
        switch self {
        case .archer: return 60
        case .cannon: return 80
        case .frost: return 70
        }
    }

    /// Seconds between shots
    var fireRate: Double {
        switch self {
        case .archer: return 0.8
        case .cannon: return 2.5
        case .frost: return 1.2
        }
    }

    var color: Color {
        switch self {
        case .archer: return Color(red: 0.20, green: 0.60, blue: 0.20)
        case .cannon: return Color(red: 0.20, green: 0.40, blue: 0.80)
        case .frost: return Color(red: 0.50, green: 0.20, blue: 0.80)
        }
    }

    /// SF Symbol name for tower picker UI
    var iconName: String {
        switch self {
        case .archer: return "arrow.up"
        case .cannon: return "circle.fill"
        case .frost: return "snowflake"
        }
    }

    var emoji: String {
        switch self {
        case .archer: return "🏹"
        case .cannon: return "💣"
        case .frost:  return "❄️"
        }
    }

    /// Splash radius in game-space units (0 = single target)
    var splashRadius: Double {
        switch self {
        case .archer: return 0
        case .cannon: return 20
        case .frost: return 0
        }
    }

    /// Slow factor applied to enemy speed (1.0 = no slow, 0.5 = half speed)
    var slowFactor: Double {
        switch self {
        case .archer: return 1.0
        case .cannon: return 1.0
        case .frost: return 0.5
        }
    }

    var description: String {
        switch self {
        case .archer: return "Fast single-target attacks. Low cost, reliable damage."
        case .cannon: return "Slow but powerful. Splash damage hits multiple enemies."
        case .frost: return "Slows enemies by 50%, making them easy targets for other towers."
        }
    }
}
