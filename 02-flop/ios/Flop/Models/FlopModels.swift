import Foundation
import SwiftData

enum Suit: String, CaseIterable {
    case spades = "♠", hearts = "♥", diamonds = "♦", clubs = "♣"
    var isRed: Bool { self == .hearts || self == .diamonds }
    var symbol: String { rawValue }
}

enum Rank: Int, CaseIterable, Comparable {
    case two=2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    var shortName: String {
        switch self {
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        default: return "\(rawValue)"
        }
    }
    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct PlayingCard: Identifiable, Hashable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    var label: String { "\(rank.shortName)\(suit.symbol)" }
}

enum PokerPosition: String, CaseIterable {
    case utg = "UTG", mp = "MP", co = "CO", btn = "BTN", sb = "SB", bb = "BB"
    var fullName: String {
        switch self {
        case .utg: return "Under the Gun"
        case .mp: return "Middle Position"
        case .co: return "Cutoff"
        case .btn: return "Button"
        case .sb: return "Small Blind"
        case .bb: return "Big Blind"
        }
    }
    var index: Int {
        switch self {
        case .utg: return 0
        case .mp: return 1
        case .co: return 2
        case .btn: return 3
        case .sb: return 4
        case .bb: return 5
        }
    }
}

enum PreFlopAction: String, CaseIterable {
    case raise = "Raise"
    case call = "Call"
    case fold = "Fold"
}

struct HandQuiz {
    let card1: PlayingCard
    let card2: PlayingCard
    let position: PokerPosition
    let correctAction: PreFlopAction
    let explanation: String

    var isSuited: Bool { card1.suit == card2.suit }
    var handName: String {
        let r1 = max(card1.rank, card2.rank)
        let r2 = min(card1.rank, card2.rank)
        if r1 == r2 { return "\(r1.shortName)\(r2.shortName)" }
        return "\(r1.shortName)\(r2.shortName)\(isSuited ? "s" : "o")"
    }
}

@Model
final class FlopQuizRecord {
    var date: Date
    var handName: String
    var position: String
    var wasCorrect: Bool

    init(date: Date = .now, handName: String, position: String, wasCorrect: Bool) {
        self.date = date
        self.handName = handName
        self.position = position
        self.wasCorrect = wasCorrect
    }
}

@Model
final class FlopSession {
    var date: Date
    var duration: Int // seconds
    var gameType: String
    var notes: String
    var handCount: Int

    init(date: Date = .now, duration: Int = 0, gameType: String = "NL Hold'em", notes: String = "", handCount: Int = 0) {
        self.date = date
        self.duration = duration
        self.gameType = gameType
        self.notes = notes
        self.handCount = handCount
    }
}

@Model
final class FlopSettings {
    var hasCompletedOnboarding: Bool
    var preferredPosition: String
    var showExplanations: Bool
    var hapticsEnabled: Bool
    var dailyGoal: Int
    var isPro: Bool

    init() {
        self.hasCompletedOnboarding = false
        self.preferredPosition = "BTN"
        self.showExplanations = true
        self.hapticsEnabled = true
        self.dailyGoal = 20
        self.isPro = false
    }
}
