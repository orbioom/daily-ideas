import SwiftUI

/// Where a board game sits in the user's collection lifecycle.
enum CollectionStatus: String, Codable, CaseIterable, Identifiable {
    case owned
    case wishlist
    case previouslyOwned
    case wantToPlay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .owned: return "Owned"
        case .wishlist: return "Wishlist"
        case .previouslyOwned: return "Previously Owned"
        case .wantToPlay: return "Want to Play"
        }
    }

    var shortLabel: String {
        switch self {
        case .owned: return "Owned"
        case .wishlist: return "Wishlist"
        case .previouslyOwned: return "Sold"
        case .wantToPlay: return "To Play"
        }
    }

    var symbol: String {
        switch self {
        case .owned: return "checkmark.seal.fill"
        case .wishlist: return "star.fill"
        case .previouslyOwned: return "shippingbox.fill"
        case .wantToPlay: return "hourglass"
        }
    }

    var color: Color {
        switch self {
        case .owned: return Theme.success
        case .wishlist: return Theme.accent
        case .previouslyOwned: return Theme.textSecondary
        case .wantToPlay: return Theme.warning
        }
    }
}
