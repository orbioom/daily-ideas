import SwiftUI

/// AppStorage keys, centralized so views and the engine agree on names.
enum PrefKey {
    static let onboarded = "arcana.onboarded"
    static let haptics = "arcana.haptics"
    static let allowReversed = "arcana.allowReversed"
    static let reminderOn = "arcana.reminderOn"
    static let reminderHour = "arcana.reminderHour"
    static let reminderMinute = "arcana.reminderMinute"
    static let deckBack = "arcana.deckBack"
}

/// The card-back gradient style, selectable in Settings. Changes the look of the
/// reverse face shown before a card is revealed.
enum DeckBack: String, CaseIterable, Identifiable {
    case midnight, dusk, ocean, ember

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnight: return "Midnight"
        case .dusk: return "Dusk"
        case .ocean: return "Ocean"
        case .ember: return "Ember"
        }
    }

    /// Two hex stops for the back gradient (light/dark agnostic, used directly).
    private var stops: (UInt32, UInt32) {
        switch self {
        case .midnight: return (0x3B2E6E, 0x171430)
        case .dusk:     return (0x7B4A8A, 0x3A2150)
        case .ocean:    return (0x2C5A86, 0x12304A)
        case .ember:    return (0x8A463A, 0x3E1C18)
        }
    }

    var gradient: LinearGradient {
        let (a, b) = stops
        return LinearGradient(colors: [Color(hex: a), Color(hex: b)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
