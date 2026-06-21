import Foundation

// Pre-flop starting hand chart using standard GTO guidelines for 6-max NL Hold'em
enum PokerEngine {
    // Returns the correct action for a starting hand + position
    // Rankings use standard Sklansky/GTO groups
    static func correctAction(hand: HandQuiz) -> PreFlopAction {
        let ranks = [hand.card1.rank, hand.card2.rank].sorted(by: >)
        let high = ranks[0], low = ranks[1]
        let suited = hand.isSuited
        let pos = hand.position

        // Premium hands - always raise from any position
        if high == .ace && low == .ace { return .raise }
        if high == .king && low == .king { return .raise }
        if high == .queen && low == .queen { return .raise }
        if high == .jack && low == .jack { return .raise }
        if high == .ace && low == .king { return .raise }

        // Strong hands
        if high == .ten && low == .ten { return .raise }
        if high == .nine && low == .nine { return .raise }
        if high == .ace && low == .queen { return .raise }
        if high == .ace && low == .jack { return pos == .utg ? .call : .raise }
        if high == .king && low == .queen { return pos == .utg ? .fold : .raise }

        // Medium pairs
        if high == .eight && low == .eight { return pos == .utg ? .call : .raise }
        if high == .seven && low == .seven { return pos == .utg ? .fold : pos == .mp ? .call : .raise }
        if high == .six && low == .six { return pos.index < 2 ? .fold : .call }
        if high == .five && low == .five { return pos.index < 2 ? .fold : .call }
        if high == .four && low == .four { return pos == .btn || pos == .sb ? .call : .fold }
        if high == .three && low == .three { return pos == .btn || pos == .sb ? .call : .fold }
        if high == .two && low == .two { return pos == .btn ? .call : .fold }

        // Suited connectors and broadways
        if high == .ace && low == .ten {
            if suited { return .raise }
            return pos.index < 2 ? .fold : .call
        }
        if high == .ace {
            // Ace-x suited
            if suited && low.rawValue >= 5 { return pos.index < 1 ? .fold : .call }
            if suited && low == .two { return pos == .btn || pos == .sb ? .call : .fold }
            // Ace-x offsuit
            if !suited { return pos == .bb ? .call : .fold }
        }

        if high == .king && low == .jack {
            if suited { return pos.index < 1 ? .fold : .raise }
            return pos.index < 3 ? .fold : .call
        }
        if high == .king && low == .ten {
            if suited { return pos.index < 2 ? .fold : .call }
            return pos == .btn ? .call : .fold
        }
        if high == .queen && low == .jack {
            if suited { return pos.index < 1 ? .fold : .raise }
            return pos.index < 2 ? .fold : .call
        }
        if high == .queen && low == .ten {
            if suited { return pos.index < 2 ? .fold : .call }
            return pos.index < 3 ? .fold : .call
        }
        if high == .jack && low == .ten {
            if suited { return pos.index < 1 ? .fold : .raise }
            return pos.index < 3 ? .fold : .call
        }

        // Suited connectors (10-9s, 9-8s, 8-7s, 7-6s)
        let gap = high.rawValue - low.rawValue
        if suited && gap == 1 && high.rawValue >= 7 {
            return pos.index < 3 ? .fold : .call
        }
        if suited && gap == 2 && high.rawValue >= 9 {
            return pos == .btn ? .call : .fold
        }

        return .fold
    }

    static func explanation(hand: HandQuiz) -> String {
        let action = correctAction(hand: hand)
        let handName = hand.handName
        switch action {
        case .raise:
            return "\(handName) is a premium hand from \(hand.position.fullName). Always open-raise to 2.5–3bb."
        case .call:
            return "\(handName) from \(hand.position.fullName) is worth playing but not strong enough to raise from early positions. Flat call an open or limp."
        case .fold:
            return "\(handName) from \(hand.position.fullName) is too weak. Fold and wait for a better spot."
        }
    }

    // Generate a random quiz hand
    static func randomQuiz() -> HandQuiz {
        var ranks = Rank.allCases
        var suits = Suit.allCases.shuffled()
        let r1 = ranks.randomElement()!
        let r2 = ranks.randomElement()!
        let s1 = suits[0]
        let s2 = suits[Bool.random() ? 0 : 1] // sometimes same suit for suited hands
        let card1 = PlayingCard(rank: r1, suit: s1)
        let card2 = PlayingCard(rank: r2, suit: s2)
        let position = PokerPosition.allCases.randomElement()!
        let hand = HandQuiz(card1: card1, card2: card2, position: position, correctAction: .fold, explanation: "")
        let correct = correctAction(hand: hand)
        let exp = explanation(hand: hand)
        return HandQuiz(card1: card1, card2: card2, position: position, correctAction: correct, explanation: exp)
    }

    // Pre-flop hand strength guide
    static let handGroups: [(group: String, color: String, hands: [String])] = [
        ("Premium", "#FFD700", ["AA", "KK", "QQ", "JJ", "AKs", "AKo"]),
        ("Strong", "#4CAF50", ["TT", "99", "AQs", "AQo", "AJs", "KQs"]),
        ("Playable", "#2196F3", ["88", "77", "ATs", "ATo", "AJo", "KJs", "QJs", "JTs"]),
        ("Speculative", "#FF9800", ["66", "55", "A9s-A2s", "KQo", "KTs", "QTs", "T9s", "98s"]),
        ("Position-only", "#9E9E9E", ["44", "33", "22", "K9s", "Q9s", "J9s", "87s", "76s"]),
    ]

    // Pot odds basics
    static func potOddsPercentage(callAmount: Double, potBefore: Double) -> Double {
        guard callAmount > 0 else { return 0 }
        let totalPot = potBefore + callAmount
        return (callAmount / totalPot) * 100
    }

    static func breakEvenEquity(callAmount: Double, potBefore: Double) -> Double {
        return potOddsPercentage(callAmount: callAmount, potBefore: potBefore)
    }
}
