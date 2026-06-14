import SwiftUI

/// Ownership status of a bottle. Stored as rawValue.
enum BottleStatus: String, Codable, CaseIterable, Identifiable {
    case owned = "Owned"
    case wishlist = "Wishlist"
    case decant = "Decant"
    case sold = "Sold"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .owned: return "checkmark.seal"
        case .wishlist: return "heart"
        case .decant: return "eyedropper"
        case .sold: return "arrow.uturn.backward"
        }
    }

    var tint: Color {
        switch self {
        case .owned: return Theme.good
        case .wishlist: return Theme.accent
        case .decant: return Color.dyn(0x3F9BA8, 0x73C3CE)
        case .sold: return Theme.inkFaint
        }
    }

    /// Items that count toward the collection (owned bottles + decants you keep).
    var isInCollection: Bool {
        self == .owned || self == .decant
    }
}

/// Note slot in the fragrance pyramid.
enum NoteSlot: String, Codable, CaseIterable, Identifiable {
    case top = "Top"
    case heart = "Heart"
    case base = "Base"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .top: return "First impression — fleeting"
        case .heart: return "The character — the middle"
        case .base: return "The foundation — lasts longest"
        }
    }
}
