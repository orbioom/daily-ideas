import Foundation

/// The number of distinct suits used in a game. Spider always uses 104 cards
/// (two decks worth); fewer suits means easier play because more runs are same-suit.
enum SuitMode: Int, Codable, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case four = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .one: return "1 Suit"
        case .two: return "2 Suits"
        case .four: return "4 Suits"
        }
    }

    var difficultyLabel: String {
        switch self {
        case .one: return "Easy"
        case .two: return "Medium"
        case .four: return "Hard"
        }
    }

    /// 4-suit is the only mode gated behind Spindle Pro.
    var requiresPro: Bool { self == .four }

    /// The suits actually present on the table for this mode.
    /// 1 suit → all spades, 2 suits → spades + hearts, 4 suits → all four.
    var suits: [Suit] {
        switch self {
        case .one: return [.spades]
        case .two: return [.spades, .hearts]
        case .four: return [.spades, .hearts, .diamonds, .clubs]
        }
    }
}

/// How a particular game was seeded — used for stats and the New Game screen.
enum DealKind: Codable, Equatable {
    case random
    case daily(Int)          // yyyyMMdd seed int
    case numbered(Int)       // deal number

    var isDaily: Bool { if case .daily = self { return true } else { return false } }

    var dealNumber: Int? {
        if case let .numbered(n) = self { return n }
        return nil
    }
}
