import SwiftUI

/// Reader font size for passage text in the player and detail screens.
enum PassageFontSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }

    /// Base point size for the serif passage body.
    var bodySize: CGFloat {
        switch self {
        case .small:  return 17
        case .medium: return 20
        case .large:  return 24
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .small:  return 6
        case .medium: return 8
        case .large:  return 10
        }
    }
}

/// The level a freshly added passage starts at, as a preference.
enum StartingLevelPref: String, CaseIterable, Identifiable {
    case read, firstLetters
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .read:         return "Read first"
        case .firstLetters: return "First letters"
        }
    }
}

/// Default blank density preference (used as the player's blank intensity hint).
enum MaskFractionPref: String, CaseIterable, Identifiable {
    case light, half, heavy
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light (25%)"
        case .half:  return "Half (50%)"
        case .heavy: return "Heavy (75%)"
        }
    }
}
