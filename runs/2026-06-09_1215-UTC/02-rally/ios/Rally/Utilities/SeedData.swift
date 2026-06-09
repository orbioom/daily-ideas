import Foundation
import SwiftData

/// Seeds a realistic roster and ~50 completed matches on first launch so lists,
/// head-to-heads, ratings, and charts are never empty for a new user. Uses a
/// seeded pseudo-random generator so the demo data is varied but deterministic.
/// Ratings are evolved through `RatingEngine` in chronological order, exactly as
/// the live "finish match" path would, so the seeded ratings are self-consistent.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Player>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        var rng = SeededGenerator(seed: 7_345_111)

        // MARK: Players
        let me = Player(name: "You", isMe: true, rating: 3.0,
                        note: "That's you. Ratings update after every match.")
        let alex = Player(name: "Alex Rivera", rating: 3.0, note: "Lefty dinker.")
        let priya = Player(name: "Priya Shah", rating: 3.0, note: "Aggressive baseline game.")
        let marco = Player(name: "Marco Bianchi", rating: 3.0, note: "Big serve, streaky.")
        let dana = Player(name: "Dana Kim", rating: 3.0, note: "Steady doubles partner.")
        let sam = Player(name: "Sam Okafor", rating: 3.0, note: "Quick hands at the net.")

        let players = [me, alex, priya, marco, dana, sam]
        players.forEach { context.insert($0) }

        let others = [alex, priya, marco, dana, sam]

        // MARK: Matches (chronological so RatingEngine evolves correctly)
        let cal = Calendar.current
        let now = Date.now
        var matches: [Match] = []

        // Spread ~50 matches across the last ~150 days.
        let totalMatches = 50
        for i in 0..<totalMatches {
            let daysAgo = 150 - Int(Double(i) / Double(totalMatches) * 150) - Int(rng.next(upTo: 3))
            guard let date = cal.date(byAdding: .day, value: -max(0, daysAgo), to: now) else { continue }

            let sport: Sport = rng.next(upTo: 10) < 6 ? .pickleball : .tennis
            let format: MatchFormat = rng.next(upTo: 10) < 6 ? .singles : .doubles
            let pointsToWin = sport == .pickleball ? 11 : 6
            let winByTwo = true

            // Choose opponents and (for doubles) a partner.
            var pool = others.shuffled(using: &rng)
            let opp1 = pool.removeFirst()
            var mySide: [Player] = [me]
            var oppSide: [Player] = [opp1]
            if format == .doubles {
                let partner = pool.removeFirst()
                mySide.append(partner)
                let opp2 = pool.removeFirst()
                oppSide.append(opp2)
            }

            // Decide outcome with some skill bias toward "You".
            let myAdvantage = 0.54
            let iWin = rng.unit() < myAdvantage
            let gameCount = rng.next(upTo: 2) == 0 ? 2 : 3 // best-of feel
            var myGames = 0
            var oppGames = 0
            var games: [GameScore] = []
            for g in 0..<gameCount {
                // Per-game winner trends with the match outcome.
                let gameToMe: Bool
                if myGames == oppGames {
                    gameToMe = rng.unit() < (iWin ? 0.62 : 0.38)
                } else {
                    gameToMe = iWin ? (myGames > oppGames || rng.unit() < 0.6)
                                    : (oppGames > myGames ? false : rng.unit() < 0.4)
                }
                let winScore = pointsToWin + Int(rng.next(upTo: 2)) // 11 or 12/13
                let loseScore = max(0, min(winScore - 2, Int(rng.next(upTo: UInt64(pointsToWin)))))
                let myScore = gameToMe ? winScore : loseScore
                let oppScore = gameToMe ? loseScore : winScore
                games.append(GameScore(order: g, myScore: myScore, oppScore: oppScore))
                if gameToMe { myGames += 1 } else { oppGames += 1 }
                // Stop a 3-game match once someone takes 2.
                if myGames == 2 || oppGames == 2 { break }
            }

            let match = Match(date: date, sport: sport, format: format,
                              pointsToWin: pointsToWin, winByTwo: winByTwo,
                              location: rng.next(upTo: 2) == 0 ? "Riverside Courts" : "Downtown Rec",
                              isComplete: true,
                              myGamesWon: myGames, oppGamesWon: oppGames,
                              mySide: mySide, oppSide: oppSide, games: games)
            context.insert(match)
            matches.append(match)
        }

        // Evolve ratings chronologically, just like real play.
        for match in matches.sorted(by: { $0.date < $1.date }) {
            RatingEngine.apply(to: match)
        }

        try? context.save()
    }
}

/// A tiny deterministic SplitMix64 generator so seeded data is reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A value in `0..<bound`.
    mutating func next(upTo bound: UInt64) -> UInt64 {
        bound == 0 ? 0 : next() % bound
    }

    /// A `Double` in `0..<1`.
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}
