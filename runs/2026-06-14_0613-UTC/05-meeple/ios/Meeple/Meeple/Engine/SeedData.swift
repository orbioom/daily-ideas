import Foundation
import SwiftData

/// Seeds a lively sample library (>=50 games, ~6 players, >=80 plays) on first launch.
/// Deterministic via a small linear-congruential generator so demos are reproducible.
enum SeedData {

    /// Simple deterministic RNG (no Foundation randomness needed → stable seed data).
    struct LCG {
        var state: UInt64
        init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
        mutating func int(_ range: ClosedRange<Int>) -> Int {
            let span = UInt64(range.upperBound - range.lowerBound + 1)
            return range.lowerBound + Int(next() % span)
        }
        mutating func double(_ range: ClosedRange<Double>) -> Double {
            let f = Double(next() % 10_000) / 10_000.0
            return range.lowerBound + f * (range.upperBound - range.lowerBound)
        }
        mutating func bool(_ chance: Double) -> Bool {
            double(0...1) < chance
        }
    }

    // (title, designer, min, max, time, weight, year)
    private static let catalog: [(String, String, Int, Int, Int, Double, Int)] = [
        ("Catan", "Klaus Teuber", 3, 4, 90, 2.3, 1995),
        ("Carcassonne", "Klaus-Jürgen Wrede", 2, 5, 45, 1.9, 2000),
        ("Ticket to Ride", "Alan R. Moon", 2, 5, 60, 1.8, 2004),
        ("Pandemic", "Matt Leacock", 2, 4, 45, 2.4, 2008),
        ("Dominion", "Donald X. Vaccarino", 2, 4, 30, 2.4, 2008),
        ("7 Wonders", "Antoine Bauza", 3, 7, 30, 2.3, 2010),
        ("Agricola", "Uwe Rosenberg", 1, 5, 120, 3.6, 2007),
        ("Power Grid", "Friedemann Friese", 2, 6, 120, 3.3, 2004),
        ("Puerto Rico", "Andreas Seyfarth", 3, 5, 90, 3.3, 2002),
        ("Terra Mystica", "Jens Drögemüller", 2, 5, 150, 3.9, 2012),
        ("Twilight Struggle", "Ananda Gupta", 2, 2, 180, 3.6, 2005),
        ("Scythe", "Jamey Stegmaier", 1, 5, 115, 3.4, 2016),
        ("Gloomhaven", "Isaac Childres", 1, 4, 120, 3.9, 2017),
        ("Wingspan", "Elizabeth Hargrave", 1, 5, 70, 2.4, 2019),
        ("Azul", "Michael Kiesling", 2, 4, 40, 1.8, 2017),
        ("Splendor", "Marc André", 2, 4, 30, 1.8, 2014),
        ("The Castles of Burgundy", "Stefan Feld", 2, 4, 90, 3.0, 2011),
        ("Brass: Birmingham", "Gavan Brown", 2, 4, 120, 3.9, 2018),
        ("Spirit Island", "R. Eric Reuss", 1, 4, 120, 4.0, 2017),
        ("Concordia", "Mac Gerdts", 2, 5, 100, 3.0, 2013),
        ("Everdell", "James A. Wilson", 1, 4, 80, 2.8, 2018),
        ("Root", "Cole Wehrle", 2, 4, 90, 3.7, 2018),
        ("Terraforming Mars", "Jacob Fryxelius", 1, 5, 120, 3.2, 2016),
        ("A Feast for Odin", "Uwe Rosenberg", 1, 4, 120, 3.9, 2016),
        ("Lost Ruins of Arnak", "Mín & Elwen", 1, 4, 100, 2.9, 2020),
        ("Viticulture", "Jamey Stegmaier", 1, 6, 90, 2.9, 2015),
        ("Patchwork", "Uwe Rosenberg", 2, 2, 30, 1.6, 2014),
        ("Lords of Waterdeep", "Peter Lee", 2, 5, 120, 2.5, 2012),
        ("Stone Age", "Bernd Brunnhofer", 2, 4, 90, 2.5, 2008),
        ("Race for the Galaxy", "Tom Lehmann", 2, 4, 45, 3.0, 2007),
        ("El Grande", "Wolfgang Kramer", 2, 5, 90, 3.1, 1995),
        ("Tigris & Euphrates", "Reiner Knizia", 2, 4, 90, 3.5, 1997),
        ("Through the Ages", "Vlaada Chvátil", 2, 4, 180, 4.4, 2015),
        ("Great Western Trail", "Alexander Pfister", 2, 4, 150, 3.7, 2016),
        ("Orléans", "Reiner Stockhausen", 2, 4, 90, 3.1, 2014),
        ("Clank!", "Paul Dennen", 2, 4, 60, 2.2, 2016),
        ("Cascadia", "Randy Flynn", 1, 4, 45, 1.8, 2021),
        ("Kingdomino", "Bruno Cathala", 2, 4, 20, 1.2, 2016),
        ("Codenames", "Vlaada Chvátil", 2, 8, 15, 1.3, 2015),
        ("The Crew", "Thomas Sing", 2, 5, 20, 2.0, 2019),
        ("Hive", "John Yianni", 2, 2, 20, 2.3, 2001),
        ("Santorini", "Gordon Hamilton", 2, 4, 20, 1.7, 2016),
        ("Jaipur", "Sébastien Pauchon", 2, 2, 30, 1.5, 2009),
        ("Lost Cities", "Reiner Knizia", 2, 2, 30, 1.5, 1999),
        ("Welcome To...", "Benoit Turpin", 1, 100, 25, 1.8, 2018),
        ("Quacks of Quedlinburg", "Wolfgang Warsch", 2, 4, 45, 2.4, 2018),
        ("Res Arcana", "Tom Lehmann", 2, 4, 45, 2.7, 2019),
        ("Dune: Imperium", "Paul Dennen", 1, 4, 120, 3.0, 2020),
        ("Ark Nova", "Mathias Wigge", 1, 4, 150, 3.8, 2021),
        ("Maracaibo", "Alexander Pfister", 1, 4, 150, 3.7, 2019),
        ("Underwater Cities", "Vladimír Suchý", 1, 4, 150, 3.6, 2018),
        ("Calico", "Kevin Russ", 1, 4, 45, 2.6, 2020),
        ("Parks", "Henry Audubon", 1, 5, 60, 2.1, 2019),
        ("Photosynthesis", "Hjalmar Hach", 2, 4, 60, 2.5, 2017),
        ("Sagrada", "Daryl Andrews", 1, 4, 45, 1.9, 2017),
        ("Tzolk'in", "Simone Luciani", 2, 4, 120, 3.7, 2012)
    ]

    private static let playerNames = ["You", "Maya", "Theo", "Priya", "Sam", "Lena"]
    private static let locations = ["Home", "Game Café", "Theo's place", "Club Night", "Maya's"]

    static func seed(into context: ModelContext) {
        var rng = LCG(seed: 0xABCDEF12345)

        // Players (first is "me").
        var players: [Player] = []
        for (i, name) in playerNames.enumerated() {
            let p = Player(name: name, isMe: i == 0)
            context.insert(p)
            players.append(p)
        }

        // Games — first ~40 owned, then a mix of wishlist / want-to-play / sold.
        var games: [BoardGame] = []
        for (i, entry) in catalog.enumerated() {
            let status: CollectionStatus
            if i < 42 { status = .owned }
            else if i % 4 == 0 { status = .wishlist }
            else if i % 4 == 1 { status = .wantToPlay }
            else if i % 4 == 2 { status = .previouslyOwned }
            else { status = .owned }

            let rating = status == .owned ? rng.int(5...10) : rng.int(0...8)
            let g = BoardGame(
                title: entry.0, designer: entry.1,
                minPlayers: entry.2, maxPlayers: entry.3,
                playTimeMin: entry.4, weight: entry.5, yearPublished: entry.6,
                status: status, rating: rating,
                notes: ""
            )
            context.insert(g)
            games.append(g)
        }

        // Plays — only on owned games, spread over the last ~14 months.
        let ownedGames = games.filter { $0.status == .owned }
        let cal = Calendar.current
        let now = Date()

        var playsMade = 0
        // Weight some games as "favourites" → more plays, so most-played & H-index look alive.
        let favouriteCount = min(10, ownedGames.count)
        for i in 0..<ownedGames.count {
            let game = ownedGames[i]
            let isFavourite = i < favouriteCount
            let sessions = isFavourite ? rng.int(5...11) : rng.int(0...3)
            for _ in 0..<sessions {
                let daysAgo = rng.int(0...420)
                guard let date = cal.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

                let play = Play(
                    date: date,
                    durationMin: max(15, game.playTimeMin + rng.int(-15...25)),
                    location: locations[rng.int(0...(locations.count - 1))],
                    notes: "",
                    game: game
                )
                context.insert(play)

                // Choose a subset of players within the game's range.
                let lo = game.minPlayers
                let hi = min(game.maxPlayers, players.count)
                let count = hi >= lo ? rng.int(lo...hi) : lo
                var pool = players
                var chosen: [Player] = []
                for _ in 0..<min(count, pool.count) {
                    let idx = rng.int(0...(pool.count - 1))
                    chosen.append(pool.remove(at: idx))
                }

                let scored = rng.bool(0.8)
                var results: [PlayerResult] = []
                for pl in chosen {
                    let score: Int? = scored ? rng.int(20...140) : nil
                    let r = PlayerResult(
                        playerName: pl.name,
                        score: score,
                        isWinner: false,
                        colorHue: pl.colorHue,
                        play: play
                    )
                    context.insert(r)
                    results.append(r)
                }

                // Resolve winners (highest score by default; if unscored, pick one at random).
                if scored {
                    let scores = results.map { $0.score }
                    let winners = WinnerResolver.winningIndices(scores: scores, rule: .highestScore)
                    for idx in winners where idx < results.count { results[idx].isWinner = true }
                } else if !results.isEmpty {
                    let w = rng.int(0...(results.count - 1))
                    results[w].isWinner = true
                }

                play.results = results
                playsMade += 1
            }
        }

        // Ensure we cleared the >=80 bar even if randomness skewed low.
        if playsMade < 80, let topGame = ownedGames.first {
            for _ in 0..<(80 - playsMade) {
                let daysAgo = rng.int(0...420)
                guard let date = cal.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let play = Play(date: date, durationMin: topGame.playTimeMin, location: "Home", game: topGame)
                context.insert(play)
                let me = players[0]
                let r = PlayerResult(playerName: me.name, score: rng.int(20...120),
                                     isWinner: true, colorHue: me.colorHue, play: play)
                context.insert(r)
                play.results = [r]
            }
        }
    }
}
