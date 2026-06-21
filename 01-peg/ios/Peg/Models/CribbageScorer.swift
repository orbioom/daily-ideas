import Foundation

struct ScoredHand {
    let total: Int
    let breakdown: [(label: String, points: Int)]
}

struct PeggingScore {
    let points: Int
    let description: String
}

enum CribbageScorer {
    // MARK: — Hand scoring (4 cards in hand + 1 starter)

    static func scoreHand(_ hand: [Card], starter: Card, isCrib: Bool) -> ScoredHand {
        let all = hand + [starter]
        var breakdown: [(String, Int)] = []

        let fifteens = countFifteens(all)
        if fifteens > 0 { breakdown.append(("Fifteens", fifteens)) }

        let pairs = countPairs(all)
        if pairs > 0 { breakdown.append(("Pairs", pairs)) }

        let runs = countRuns(all)
        if runs > 0 { breakdown.append(("Runs", runs)) }

        let flush = countFlush(hand, starter: starter, isCrib: isCrib)
        if flush > 0 { breakdown.append(("Flush", flush)) }

        let nobs = countNobs(hand, starter: starter)
        if nobs > 0 { breakdown.append(("His Nobs", nobs)) }

        let total = breakdown.reduce(0) { $0 + $1.1 }
        return ScoredHand(total: total, breakdown: breakdown.map { (label: $0.0, points: $0.1) })
    }

    static func countFifteens(_ cards: [Card]) -> Int {
        var count = 0
        for size in 2...min(cards.count, 5) {
            for combo in combinations(cards, size) {
                if combo.map({ $0.rank.value }).reduce(0, +) == 15 { count += 1 }
            }
        }
        return count * 2
    }

    static func countPairs(_ cards: [Card]) -> Int {
        var count = 0
        for i in 0..<cards.count {
            for j in (i+1)..<cards.count {
                if cards[i].rank == cards[j].rank { count += 1 }
            }
        }
        return count * 2
    }

    static func countRuns(_ cards: [Card]) -> Int {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank.rawValue })
        let distinctRanks = rankCounts.keys.sorted()
        guard distinctRanks.count >= 3 else { return 0 }

        var runTotal = 0
        var i = 0
        while i < distinctRanks.count {
            var j = i
            while j + 1 < distinctRanks.count && distinctRanks[j+1] == distinctRanks[j] + 1 {
                j += 1
            }
            let runLength = j - i + 1
            if runLength >= 3 {
                let ranksInRun = distinctRanks[i...j]
                let multiplier = ranksInRun.reduce(1) { $0 * (rankCounts[$1]?.count ?? 1) }
                runTotal += runLength * multiplier
            }
            i = j + 1
        }
        return runTotal
    }

    static func countFlush(_ hand: [Card], starter: Card, isCrib: Bool) -> Int {
        guard hand.count == 4 else { return 0 }
        let handSuit = hand[0].suit
        guard hand.allSatisfy({ $0.suit == handSuit }) else { return 0 }
        if starter.suit == handSuit { return 5 }
        return isCrib ? 0 : 4
    }

    static func countNobs(_ hand: [Card], starter: Card) -> Int {
        return hand.contains(where: { $0.rank == .jack && $0.suit == starter.suit }) ? 1 : 0
    }

    // MARK: — Pegging scoring (running sequence of played cards)

    static func scorePegging(played: [Card], runningTotal: Int) -> PeggingScore {
        var points = 0
        var parts: [String] = []

        // Fifteen
        if runningTotal == 15 {
            points += 2
            parts.append("Fifteen-2")
        }
        // Thirty-one
        if runningTotal == 31 {
            points += 2
            parts.append("Thirty-one-2")
        }

        // Pairs: check last n cards for matching rank
        let pairScore = peggingPairs(played)
        if pairScore > 0 {
            switch pairScore {
            case 2: parts.append("Pair-2")
            case 6: parts.append("Pair Royal-6")
            case 12: parts.append("Double Pair Royal-12")
            default: break
            }
            points += pairScore
        }

        // Runs: check last n cards for a run
        let runScore = peggingRuns(played)
        if runScore > 0 {
            parts.append("Run of \(runScore)-\(runScore)")
            points += runScore
        }

        return PeggingScore(points: points, description: parts.joined(separator: ", "))
    }

    private static func peggingPairs(_ played: [Card]) -> Int {
        guard played.count >= 2 else { return 0 }
        let last = played.last!.rank
        var streak = 0
        for card in played.reversed() {
            if card.rank == last { streak += 1 } else { break }
        }
        switch streak {
        case 2: return 2
        case 3: return 6
        case 4: return 12
        default: return 0
        }
    }

    private static func peggingRuns(_ played: [Card]) -> Int {
        let maxLen = min(played.count, 7)
        for length in stride(from: maxLen, through: 3, by: -1) {
            let slice = Array(played.suffix(length))
            let rankVals = slice.map { $0.rank.rawValue }
            let sorted = rankVals.sorted()
            let isConsecutive = (1..<sorted.count).allSatisfy { sorted[$0] == sorted[$0-1] + 1 }
            let isUnique = Set(rankVals).count == rankVals.count
            if isConsecutive && isUnique { return length }
        }
        return 0
    }

    // MARK: — AI discard helper: expected hand value given crib ownership

    static func expectedHandValue(keeping: [Card], ownCrib: Bool, deck: [Card]) -> Double {
        let remaining = deck.filter { !keeping.contains($0) }
        var total = 0.0
        var count = 0
        for starter in remaining {
            let hand = scoreHand(keeping, starter: starter, isCrib: false)
            total += Double(hand.total)
            count += 1
        }
        guard count > 0 else { return 0 }
        return total / Double(count)
    }
}
