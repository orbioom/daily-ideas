import Foundation

/// The four suits, each with a display color and an SF Symbol name.
enum Suit: Int, CaseIterable, Codable, Identifiable, Hashable {
    case spades, hearts, diamonds, clubs

    var id: Int { rawValue }

    /// Red (hearts, diamonds) vs black (spades, clubs).
    enum PipColor { case red, black }

    var pipColor: PipColor {
        switch self {
        case .hearts, .diamonds: return .red
        case .spades, .clubs: return .black
        }
    }

    var isRed: Bool { pipColor == .red }

    /// SF Symbol for the suit pip.
    var symbolName: String {
        switch self {
        case .spades: return "suit.spade.fill"
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        }
    }

    /// Human-readable name for accessibility.
    var displayName: String {
        switch self {
        case .spades: return "spades"
        case .hearts: return "hearts"
        case .diamonds: return "diamonds"
        case .clubs: return "clubs"
        }
    }

    /// The suit index used by the Microsoft deal generator (clubs, diamonds, hearts, spades).
    var microsoftIndex: Int {
        switch self {
        case .clubs: return 0
        case .diamonds: return 1
        case .hearts: return 2
        case .spades: return 3
        }
    }

    /// Inverse of `microsoftIndex`.
    static func fromMicrosoftIndex(_ index: Int) -> Suit {
        switch index {
        case 0: return .clubs
        case 1: return .diamonds
        case 2: return .hearts
        default: return .spades
        }
    }
}

/// A playing card. Rank is 1...13 (Ace = 1, King = 13).
struct Card: Identifiable, Codable, Equatable, Hashable {
    let suit: Suit
    let rank: Int

    /// Stable identity for SwiftUI; suit+rank is unique within a 52-card deck.
    var id: Int { suit.rawValue * 13 + rank }

    /// Short rank label: A, 2...10, J, Q, K. Falls back gracefully for out-of-range values.
    var rankLabel: String {
        switch rank {
        case 1: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        case 2...10: return String(rank)
        default: return "?"
        }
    }

    /// Spoken rank for accessibility.
    var rankSpoken: String {
        switch rank {
        case 1: return "Ace"
        case 11: return "Jack"
        case 12: return "Queen"
        case 13: return "King"
        case 2...10: return String(rank)
        default: return "card"
        }
    }

    /// Full accessibility description, e.g. "Ace of spades".
    var accessibilityName: String {
        "\(rankSpoken) of \(suit.displayName)"
    }

    var isRed: Bool { suit.isRed }
}
