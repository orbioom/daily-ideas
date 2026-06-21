import Foundation

enum BJAction: String, CaseIterable {
    case hit = "Hit"
    case stand = "Stand"
    case double = "Double"
    case split = "Split"
    case surrender = "Surrender"

    var systemImage: String {
        switch self {
        case .hit: return "hand.point.up.fill"
        case .stand: return "hand.raised.fill"
        case .double: return "arrow.up.circle.fill"
        case .split: return "arrow.left.arrow.right.circle.fill"
        case .surrender: return "flag.fill"
        }
    }
}

struct HandScenario {
    let playerCards: [Int]
    let dealerUpcard: Int

    var isSoft: Bool {
        playerCards.contains(1) && playerCards.reduce(0, +) + 10 <= 21
    }

    var isPair: Bool {
        playerCards.count == 2 && playerCards[0] == playerCards[1]
    }

    var hardTotal: Int {
        let sum = playerCards.reduce(0, +)
        let hasAce = playerCards.contains(1)
        return hasAce && sum + 10 <= 21 ? sum + 10 : sum
    }

    var softTotal: Int {
        playerCards.reduce(0, +) + 10
    }

    var pairCard: Int {
        playerCards[0]
    }

    var displayString: String {
        let cardStr: String
        if isPair {
            let c = pairCard == 1 ? "A" : "\(pairCard)"
            cardStr = "\(c),\(c)"
        } else if isSoft {
            let other = playerCards.filter { $0 != 1 }.first ?? 0
            cardStr = "A,\(other)"
        } else {
            cardStr = "\(hardTotal)"
        }
        let d = dealerUpcard == 1 ? "A" : "\(dealerUpcard)"
        return "\(cardStr) vs \(d)"
    }
}

struct BasicStrategy {
    static func correctAction(for scenario: HandScenario) -> BJAction {
        let d = scenario.dealerUpcard

        if scenario.isPair {
            return pairAction(pair: scenario.pairCard, dealer: d)
        }
        if scenario.isSoft {
            return softAction(softTotal: scenario.softTotal, dealer: d)
        }
        return hardAction(hardTotal: scenario.hardTotal, dealer: d)
    }

    private static func hardAction(hardTotal: Int, dealer: Int) -> BJAction {
        switch hardTotal {
        case ...8:
            return .hit
        case 9:
            return (3...6).contains(dealer) ? .double : .hit
        case 10:
            return (2...9).contains(dealer) ? .double : .hit
        case 11:
            return dealer == 1 ? .hit : .double
        case 12:
            return (4...6).contains(dealer) ? .stand : .hit
        case 13...16:
            return (2...6).contains(dealer) ? .stand : .hit
        default:
            return .stand
        }
    }

    private static func softAction(softTotal: Int, dealer: Int) -> BJAction {
        switch softTotal {
        case ...17:
            return .hit
        case 18:
            if (2...6).contains(dealer) { return .double }
            if (9...10).contains(dealer) || dealer == 1 { return .hit }
            return .stand
        case 19:
            return dealer == 6 ? .double : .stand
        default:
            return .stand
        }
    }

    private static func pairAction(pair: Int, dealer: Int) -> BJAction {
        switch pair {
        case 1, 8:
            return .split
        case 2, 3:
            return (2...7).contains(dealer) ? .split : .hit
        case 4:
            return (5...6).contains(dealer) ? .split : .hit
        case 5:
            return (2...9).contains(dealer) ? .double : .hit
        case 6:
            return (2...6).contains(dealer) ? .split : .hit
        case 7:
            return (2...7).contains(dealer) ? .split : .hit
        case 9:
            if dealer == 7 || dealer == 10 || dealer == 1 { return .stand }
            return .split
        case 10:
            return .stand
        default:
            return .hit
        }
    }

    static func randomScenario() -> HandScenario {
        let dealerUpcard = Int.random(in: 1...10)
        let roll = Int.random(in: 0...2)
        var cards: [Int]
        if roll == 0 {
            let c = Int.random(in: 1...10)
            cards = [c, c]
        } else if roll == 1 {
            let other = Int.random(in: 2...9)
            cards = [1, other]
        } else {
            let total = Int.random(in: 5...20)
            let a = Int.random(in: 2...min(total - 2, 10))
            let b = total - a
            if b >= 2 && b <= 10 {
                cards = [a, b]
            } else {
                cards = [6, 5]
            }
        }
        return HandScenario(playerCards: cards, dealerUpcard: dealerUpcard)
    }
}
