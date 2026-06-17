import SwiftUI

/// Lifecycle of a cook.
enum CookStatus: String, CaseIterable, Identifiable, Codable {
    case planned, cooking, resting, done
    var id: String { rawValue }

    var label: String {
        switch self {
        case .planned: return "Planned"
        case .cooking: return "Cooking"
        case .resting: return "Resting"
        case .done: return "Done"
        }
    }

    var symbol: String {
        switch self {
        case .planned: return "calendar"
        case .cooking: return "flame.fill"
        case .resting: return "pause.circle.fill"
        case .done: return "checkmark.seal.fill"
        }
    }

    var hue: Color {
        switch self {
        case .planned: return Theme.inkSoft
        case .cooking: return Theme.accent
        case .resting: return Theme.ember
        case .done: return Theme.good
        }
    }

    /// Active means it currently occupies a "live cook" slot (Free tier allows 1).
    var isActive: Bool {
        self == .cooking || self == .resting
    }
}
