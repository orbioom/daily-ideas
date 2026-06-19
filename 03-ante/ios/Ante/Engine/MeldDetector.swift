import Foundation

struct Meld: Identifiable {
    let id = UUID()
    let cards: [PlayingCard]
    let type: MeldType

    enum MeldType { case set, run }
}

struct MeldDetector {
    static func findBestMelds(_ hand: [PlayingCard]) -> ([Meld], [PlayingCard]) {
        let sorted = hand.sorted { $0.sortKey < $1.sortKey }
        var bestMelds: [Meld] = []
        var bestDeadwood: [PlayingCard] = sorted
        var bestDeadwoodValue = sorted.reduce(0) { $0 + $1.value }

        let possibleMelds = findAllPossibleMelds(sorted)
        let combos = findNonOverlappingCombos(possibleMelds, hand: sorted)
        for combo in combos {
            let usedIds = Set(combo.flatMap { $0.cards.map { $0.id } })
            let deadwood = sorted.filter { !usedIds.contains($0.id) }
            let dv = deadwood.reduce(0) { $0 + $1.value }
            if dv < bestDeadwoodValue {
                bestDeadwoodValue = dv
                bestDeadwood = deadwood
                bestMelds = combo
            }
        }
        return (bestMelds, bestDeadwood)
    }

    static func deadwoodValue(_ cards: [PlayingCard]) -> Int {
        cards.reduce(0) { $0 + $1.value }
    }

    private static func findAllPossibleMelds(_ hand: [PlayingCard]) -> [Meld] {
        var melds: [Meld] = []

        let byRank = Dictionary(grouping: hand) { $0.rank }
        for (_, cards) in byRank {
            if cards.count >= 3 {
                melds.append(Meld(cards: Array(cards.prefix(3)), type: .set))
                if cards.count == 4 {
                    melds.append(Meld(cards: cards, type: .set))
                    // Also add all 3-card subsets of a 4-card set
                    for i in 0..<4 {
                        var subset = cards
                        subset.remove(at: i)
                        melds.append(Meld(cards: subset, type: .set))
                    }
                }
            }
        }

        let bySuit = Dictionary(grouping: hand) { $0.suit }
        for (_, cards) in bySuit {
            let sortedCards = cards.sorted { $0.rank.rawValue < $1.rank.rawValue }
            var i = 0
            while i < sortedCards.count {
                var j = i + 1
                while j < sortedCards.count && sortedCards[j].rank.rawValue == sortedCards[j-1].rank.rawValue + 1 {
                    j += 1
                }
                if j - i >= 3 {
                    for start in i..<j {
                        for end in (start+2)..<j {
                            melds.append(Meld(cards: Array(sortedCards[start...end]), type: .run))
                        }
                    }
                }
                i = j
            }
        }
        return melds
    }

    private static func findNonOverlappingCombos(_ melds: [Meld], hand: [PlayingCard]) -> [[Meld]] {
        var results: [[Meld]] = [[]]
        let sorted = melds.sorted { $0.cards.count > $1.cards.count }
        var used: Set<UUID> = []
        var current: [Meld] = []
        for meld in sorted {
            let ids = Set(meld.cards.map { $0.id })
            if ids.isDisjoint(with: used) {
                current.append(meld)
                used.formUnion(ids)
            }
        }
        if !current.isEmpty {
            results.append(current)
        }

        // Also try each meld individually for single-meld solutions
        for meld in melds {
            results.append([meld])
        }
        return results
    }
}
