import SwiftUI

/// Pro entitlement helpers. One-time purchase, no subscriptions.
enum Pro {
    static let price = "$5.99"
    static let freeCustomPresetLimit = 3

    /// Reason the paywall was surfaced — drives the headline copy.
    enum Reason {
        case ambient
        case bell
        case presetLimit
        case general

        var title: String {
            switch self {
            case .ambient: return "Soundscapes are a Pro feature"
            case .bell: return "Extra bells are a Pro feature"
            case .presetLimit: return "More presets with Pro"
            case .general: return "Unlock Bell Pro"
            }
        }

        var detail: String {
            switch self {
            case .ambient:
                return "Rain, ocean, and drone soundscapes are part of Bell Pro."
            case .bell:
                return "The chime and gong bells are part of Bell Pro."
            case .presetLimit:
                return "Free Bell keeps 3 custom presets. Go Pro for unlimited."
            case .general:
                return "One calm purchase unlocks everything, forever."
            }
        }
    }
}
