import SwiftUI

/// A card's learning maturity, derived from its SRS state.
enum Maturity: String, CaseIterable, Identifiable {
    case new = "New"
    case learning = "Learning"
    case young = "Young"
    case mature = "Mature"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .new: return Theme.accent
        case .learning: return Theme.warn
        case .young: return Color(hex: 0x4C8DF6)
        case .mature: return Theme.good
        }
    }

    var systemImage: String {
        switch self {
        case .new: return "sparkles"
        case .learning: return "hourglass"
        case .young: return "leaf.fill"
        case .mature: return "tree.fill"
        }
    }
}
