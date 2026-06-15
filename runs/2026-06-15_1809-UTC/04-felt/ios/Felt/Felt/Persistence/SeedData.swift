import Foundation
import SwiftData

/// Seeds a rich, believable history on first launch so every screen and chart looks alive:
/// 50+ sessions over ~6 months (mixed cash & tournaments, varied stakes/locations/games,
/// a realistic win/loss distribution that nets a modest profit) plus a few bankroll
/// transactions. Gated by a flag so it only ever runs once, and never overwrites real data.
enum SeedData {
    private static let seededKey = "didSeedFeltData"

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        // Don't seed if the user already has data.
        let sessionDescriptor = FetchDescriptor<Session>()
        let existing = (try? context.fetch(sessionDescriptor)) ?? []
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        let sessions = makeSessions()
        for s in sessions { context.insert(s) }
        for t in makeTransactions() { context.insert(t) }

        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: - Generation

    private struct CashVenue {
        let location: String
        let stakes: String
        let buyIn: Decimal
        let game: GameType
    }

    private static let cashVenues: [CashVenue] = [
        CashVenue(location: "Bellagio", stakes: "1/3", buyIn: 300, game: .nlhe),
        CashVenue(location: "Bellagio", stakes: "2/5", buyIn: 500, game: .nlhe),
        CashVenue(location: "Aria", stakes: "1/2", buyIn: 200, game: .nlhe),
        CashVenue(location: "Aria", stakes: "2/5", buyIn: 600, game: .plo),
        CashVenue(location: "The Lodge", stakes: "1/2", buyIn: 250, game: .nlhe),
        CashVenue(location: "Home Game", stakes: "0.5/1", buyIn: 100, game: .nlhe),
        CashVenue(location: "Commerce", stakes: "2/3", buyIn: 400, game: .plo),
        CashVenue(location: "Wynn", stakes: "1/3", buyIn: 300, game: .nlhe),
        CashVenue(location: "Borgata", stakes: "1/2", buyIn: 200, game: .mixed)
    ]

    private struct TourneyVenue {
        let location: String
        let label: String
        let buyIn: Decimal
        let game: GameType
    }

    private static let tourneyVenues: [TourneyVenue] = [
        TourneyVenue(location: "Wynn", label: "$400 Daily", buyIn: 400, game: .nlhe),
        TourneyVenue(location: "Aria", label: "$240 Nightly", buyIn: 240, game: .nlhe),
        TourneyVenue(location: "The Lodge", label: "$150 Bounty", buyIn: 150, game: .nlhe),
        TourneyVenue(location: "Borgata", label: "$600 Open", buyIn: 600, game: .nlhe),
        TourneyVenue(location: "Commerce", label: "$300 PLO", buyIn: 300, game: .plo)
    ]

    /// A small deterministic PRNG so the seeded data is identical and reproducible.
    private struct SeededRNG: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed != 0 ? seed : 0x9E3779B97F4A7C15 }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    private static func makeSessions() -> [Session] {
        var rng = SeededRNG(seed: 0xF31D_2026_0615)
        var sessions: [Session] = []
        let cal = Calendar.current
        let now = Date()

        // ~56 sessions spread across the last ~180 days.
        let count = 56
        for i in 0..<count {
            // Spread roughly every 3 days, with a little jitter.
            let dayOffset = -(i * 3) - Int.random(in: 0...2, using: &rng)
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            // ~75% cash, ~25% tournaments.
            let isTournament = Int.random(in: 0...3, using: &rng) == 0

            if isTournament {
                sessions.append(makeTournament(date: date, rng: &rng))
            } else {
                sessions.append(makeCash(date: date, rng: &rng))
            }
        }
        return sessions
    }

    private static func makeCash(date: Date, rng: inout SeededRNG) -> Session {
        let venue = cashVenues[Int.random(in: 0..<cashVenues.count, using: &rng)]
        let durationMinutes = Int.random(in: 120...420, using: &rng)
        let buyIn = venue.buyIn

        // A believable result: many small swings, occasional big win/loss.
        // Result expressed as a multiple of the buy-in, slightly positive on average.
        let roll = Int.random(in: 0...100, using: &rng)
        let resultMultiple: Double
        switch roll {
        case 0..<14:   resultMultiple = -1.0                                  // busted the buy-in
        case 14..<40:  resultMultiple = -Double.random(in: 0.2...0.8, using: &rng)
        case 40..<55:  resultMultiple = Double.random(in: -0.1...0.1, using: &rng)
        case 55..<86:  resultMultiple = Double.random(in: 0.2...1.4, using: &rng)
        default:       resultMultiple = Double.random(in: 1.5...3.5, using: &rng)   // a heater
        }

        let profit = roundedMoney(venue.buyIn, times: resultMultiple)
        let cashOut = max(0, buyIn + profit)

        let tags = ["", "Grind", "Weekend", "Trip", ""]
        return Session(date: date,
                       format: .cash,
                       gameType: venue.game,
                       location: venue.location,
                       stakes: venue.stakes,
                       durationMinutes: durationMinutes,
                       buyIn: buyIn,
                       cashOut: cashOut,
                       notes: "",
                       tag: tags[Int.random(in: 0..<tags.count, using: &rng)])
    }

    private static func makeTournament(date: Date, rng: inout SeededRNG) -> Session {
        let venue = tourneyVenues[Int.random(in: 0..<tourneyVenues.count, using: &rng)]
        let durationMinutes = Int.random(in: 180...600, using: &rng)
        let entries = Int.random(in: 60...420, using: &rng)

        // Most tournaments lose the buy-in; occasionally a deep run or a win.
        let roll = Int.random(in: 0...100, using: &rng)
        let prize: Decimal
        let place: Int
        switch roll {
        case 0..<70:
            prize = 0                                                          // no cash
            place = Int.random(in: (entries / 3)...entries, using: &rng)
        case 70..<90:
            prize = roundedMoney(venue.buyIn, times: Double.random(in: 1.5...4.0, using: &rng))   // min-cash / mid
            place = Int.random(in: 5...max(6, entries / 8), using: &rng)
        default:
            prize = roundedMoney(venue.buyIn, times: Double.random(in: 6.0...22.0, using: &rng))  // final table
            place = Int.random(in: 1...4, using: &rng)
        }

        return Session(date: date,
                       format: .tournament,
                       gameType: venue.game,
                       location: venue.location,
                       stakes: venue.label,
                       durationMinutes: durationMinutes,
                       buyIn: venue.buyIn,
                       cashOut: prize,
                       tournamentEntries: entries,
                       tournamentPlace: place,
                       notes: "",
                       tag: "Tournament")
    }

    /// Multiply a buy-in by a factor and round to the nearest $5 for clean figures.
    private static func roundedMoney(_ base: Decimal, times factor: Double) -> Decimal {
        let raw = NSDecimalNumber(decimal: base).doubleValue * factor
        let nearest5 = (raw / 5.0).rounded() * 5.0
        return Decimal(nearest5)
    }

    private static func makeTransactions() -> [BankrollTransaction] {
        let cal = Calendar.current
        let now = Date()
        func dateAgo(_ days: Int) -> Date {
            cal.date(byAdding: .day, value: -days, to: now) ?? now
        }
        return [
            BankrollTransaction(date: dateAgo(185), amount: 3000, kind: .deposit, note: "Initial bankroll"),
            BankrollTransaction(date: dateAgo(120), amount: 1000, kind: .deposit, note: "Top-up"),
            BankrollTransaction(date: dateAgo(60), amount: 800, kind: .withdrawal, note: "Withdrew for rent"),
            BankrollTransaction(date: dateAgo(20), amount: 1500, kind: .deposit, note: "Moving up stakes")
        ]
    }
}
