import Foundation

/// The mode a play session is running in. Drives win/lose rules and persistence.
enum GameMode: String, Codable, Hashable {
    case level
    case zen
    case daily

    var title: String {
        switch self {
        case .level: return "Level"
        case .zen: return "Zen"
        case .daily: return "Daily"
        }
    }
}
