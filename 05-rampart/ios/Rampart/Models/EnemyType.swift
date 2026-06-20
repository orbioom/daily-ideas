import Foundation

enum EnemyType: String, CaseIterable {
    case goblin
    case orc
    case troll
    case dragon

    var baseHP: Double {
        switch self {
        case .goblin: return 50
        case .orc:    return 120
        case .troll:  return 300
        case .dragon: return 800
        }
    }

    var baseSpeed: Double {
        switch self {
        case .goblin: return 80
        case .orc:    return 45
        case .troll:  return 25
        case .dragon: return 100
        }
    }

    var reward: Int {
        switch self {
        case .goblin: return 5
        case .orc:    return 10
        case .troll:  return 20
        case .dragon: return 50
        }
    }

    var emoji: String {
        switch self {
        case .goblin: return "👺"
        case .orc:    return "👹"
        case .troll:  return "🧌"
        case .dragon: return "🐉"
        }
    }

    /// Render diameter in game-space units
    var size: Double {
        switch self {
        case .goblin: return 12
        case .orc:    return 16
        case .troll:  return 22
        case .dragon: return 28
        }
    }

    var displayName: String { rawValue.capitalized }
}
