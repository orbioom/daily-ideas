import Foundation

enum PlayerSeat: Int, CaseIterable {
    case south = 0, west = 1, north = 2, east = 3
    var isHuman: Bool { self == .south }
    var isHumanTeam: Bool { self == .south || self == .north }
    var partner: PlayerSeat {
        switch self {
        case .south: return .north
        case .north: return .south
        case .west: return .east
        case .east: return .west
        }
    }
    var displayName: String {
        switch self {
        case .south: return "You"
        case .west: return "West"
        case .north: return "Partner"
        case .east: return "East"
        }
    }
}

enum BidPhase { case round1, round2 }
enum GamePhase { case dealing, bidding, playing, handOver, gameOver }

struct TrickPlay {
    let player: PlayerSeat
    let card: Card
}

struct Trick {
    var plays: [TrickPlay] = []

    /// The nominal suit of the first card led (before bower adjustments).
    var ledSuit: Suit? { plays.first.map { $0.card.suit } }

    /// Determine who won the trick. Returns nil until all plays are in.
    func winner(trump: Suit) -> PlayerSeat? {
        guard plays.count >= 3 else { return nil }
        var best = plays[0]
        for play in plays.dropFirst() {
            if beats(play.card, best.card, ledSuit: ledSuit, trump: trump) {
                best = play
            }
        }
        return best.player
    }

    /// Returns true if card `a` beats card `b` given the led suit and trump.
    private func beats(_ a: Card, _ b: Card, ledSuit: Suit?, trump: Suit) -> Bool {
        let aIsTrump = a.effectiveSuit(trump: trump) == trump
        let bIsTrump = b.effectiveSuit(trump: trump) == trump

        if aIsTrump && !bIsTrump { return true }
        if !aIsTrump && bIsTrump { return false }

        if aIsTrump && bIsTrump {
            return a.trumpPower(trump: trump) > b.trumpPower(trump: trump)
        }

        // Neither is trump — led-suit follower beats non-follower
        let aFollows = a.effectiveSuit(trump: trump) == ledSuit
        let bFollows = b.effectiveSuit(trump: trump) == ledSuit
        if aFollows && !bFollows { return true }
        if !aFollows && bFollows { return false }

        return a.rank > b.rank
    }
}

struct HandResult {
    let makerTeamIsHuman: Bool
    let tricksHuman: Int
    let tricksAI: Int
    let wentAlone: Bool
    let alonePlayer: PlayerSeat?

    var humanTeamPoints: Int {
        if makerTeamIsHuman {
            if wentAlone {
                // Alone: 4 pts for all 5, 1 pt for 3-4, 0 for euchre
                return tricksHuman >= 5 ? 4 : (tricksHuman >= 3 ? 1 : 0)
            }
            // With partner: 2 pts for march (5), 1 pt for making (3-4), 0 for euchre
            return tricksHuman >= 5 ? 2 : (tricksHuman >= 3 ? 1 : 0)
        } else {
            // Defenders: 2 pts for euchring the makers
            return tricksHuman >= 3 ? 2 : 0
        }
    }

    var aiTeamPoints: Int {
        if !makerTeamIsHuman {
            if wentAlone {
                return tricksAI >= 5 ? 4 : (tricksAI >= 3 ? 1 : 0)
            }
            return tricksAI >= 5 ? 2 : (tricksAI >= 3 ? 1 : 0)
        } else {
            return tricksAI >= 3 ? 2 : 0
        }
    }

    var resultDescription: String {
        if makerTeamIsHuman {
            if tricksHuman >= 5 { return wentAlone ? "Lone Hand! All 5 tricks!" : "March! All 5 tricks!" }
            if tricksHuman >= 3 { return "Made it! \(tricksHuman) tricks." }
            return "Euchred! Opponents score 2."
        } else {
            if tricksAI >= 5 { return "Opponents marched. All 5 tricks." }
            if tricksAI >= 3 { return "Opponents made it. \(tricksAI) tricks." }
            return "Euchred them! You score 2."
        }
    }
}
