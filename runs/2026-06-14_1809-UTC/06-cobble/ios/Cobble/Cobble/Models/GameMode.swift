import SwiftUI

/// The two play modes. Classic is an endless seeded game; Daily is the date-seeded
/// challenge everyone shares.
enum GameMode: String, CaseIterable, Identifiable, Codable {
    case classic
    case daily

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .daily: return "Daily"
        }
    }

    var symbol: String {
        switch self {
        case .classic: return "square.grid.3x3.fill"
        case .daily: return "calendar"
        }
    }

    var tint: Color {
        switch self {
        case .classic: return Theme.accent
        case .daily: return Theme.good
        }
    }
}
