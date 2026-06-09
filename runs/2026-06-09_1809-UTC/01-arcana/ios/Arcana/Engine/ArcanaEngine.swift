import Foundation

/// A small, deterministic SplitMix64 pseudo-random generator. Used so the daily
/// card is stable per calendar day and spread draws are reproducible from a seed.
/// We deliberately avoid SystemRandomNumberGenerator for the daily draw.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Pure, static reading + statistics engine. All division and empty-collection
/// access is guarded so user paths never crash.
enum ArcanaEngine {

    // MARK: - Seeding

    /// A stable 64-bit hash of a string (FNV-1a). Deterministic across launches,
    /// unlike Swift's `Hashable` hashing which is randomized per process.
    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001B3
        }
        return hash
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    // MARK: - Daily card

    /// The deterministic card of the day for a given calendar date. Seeded from
    /// the yyyy-MM-dd string so it stays the same all day and across launches.
    static func dailyCard(for date: Date, allowReversed: Bool) -> (card: TarotCard, reversed: Bool) {
        let deck = TarotDeck.all
        guard !deck.isEmpty else {
            // Unreachable in practice (static deck has 78 cards), but keep total.
            return (TarotCard(id: -1, name: "—", arcana: .major, suit: nil, number: 0,
                              upright: [], reversed: [], uprightMeaning: "", reversedMeaning: "",
                              element: "", symbol: "moon.fill"), false)
        }
        var rng = SeededGenerator(seed: stableHash(dayKey(for: date)))
        let index = Int(rng.next() % UInt64(deck.count))
        let reversed = allowReversed ? (rng.next() % 2 == 0) : false
        return (deck[index], reversed)
    }

    // MARK: - Spread draw

    /// Draw unique cards for a spread using a Fisher–Yates shuffle with a fresh
    /// random seed each call. Reversed orientation is per card when allowed.
    static func draw(spread: Spread, allowReversed: Bool) -> [(cardID: Int, reversed: Bool)] {
        let count = max(0, spread.cardCount)
        guard count > 0 else { return [] }

        var ids = TarotDeck.all.map { $0.id }
        guard !ids.isEmpty else { return [] }

        var sysRng = SystemRandomNumberGenerator()
        // Partial Fisher–Yates: only shuffle the first `count` slots.
        let n = ids.count
        let pick = min(count, n)
        if n > 1 {
            for i in 0..<pick {
                let j = Int.random(in: i..<n, using: &sysRng)
                ids.swapAt(i, j)
            }
        }

        return (0..<pick).map { i in
            let reversed = allowReversed ? Bool.random(using: &sysRng) : false
            return (cardID: ids[i], reversed: reversed)
        }
    }

    // MARK: - Statistics

    struct MonthCount: Identifiable {
        let id: String        // "yyyy-MM"
        let date: Date        // first of month
        let label: String     // "Jan"
        let count: Int
    }

    struct SuitSlice: Identifiable {
        let id: String
        let suit: Suit
        let count: Int
    }

    struct CardRank: Identifiable {
        let id: Int           // cardID
        let card: TarotCard
        let count: Int
    }

    struct Stats {
        var totalReadings: Int = 0
        var currentStreak: Int = 0
        var majorSharePercent: Int = 0      // 0…100
        var uprightCount: Int = 0
        var reversedCount: Int = 0
        var topCards: [CardRank] = []
        var suitDistribution: [SuitSlice] = []
        var perMonth: [MonthCount] = []

        var totalCardsDrawn: Int { uprightCount + reversedCount }
        var uprightPercent: Int {
            let total = totalCardsDrawn
            guard total > 0 else { return 0 }
            return Int((Double(uprightCount) / Double(total) * 100).rounded())
        }
        var reversedPercent: Int { totalCardsDrawn > 0 ? 100 - uprightPercent : 0 }
        var hasData: Bool { totalReadings > 0 }
    }

    static func stats(for readings: [Reading]) -> Stats {
        var s = Stats()
        s.totalReadings = readings.count
        guard !readings.isEmpty else { return s }

        s.currentStreak = currentStreak(readings)

        // Flatten drawn cards.
        let drawn = readings.flatMap { $0.cards }
        var majorCount = 0
        var suitCounts: [Suit: Int] = [:]
        var cardCounts: [Int: Int] = [:]

        for d in drawn {
            if d.isReversed { s.reversedCount += 1 } else { s.uprightCount += 1 }
            cardCounts[d.cardID, default: 0] += 1
            if let card = d.card {
                if card.arcana == .major { majorCount += 1 }
                if let suit = card.suit { suitCounts[suit, default: 0] += 1 }
            }
        }

        let totalDrawn = drawn.count
        s.majorSharePercent = totalDrawn > 0 ? Int((Double(majorCount) / Double(totalDrawn) * 100).rounded()) : 0

        // Top cards (most drawn), ranked.
        s.topCards = cardCounts
            .compactMap { id, count -> CardRank? in
                guard let card = TarotDeck.card(id: id) else { return nil }
                return CardRank(id: id, card: card, count: count)
            }
            .sorted { lhs, rhs in
                lhs.count != rhs.count ? lhs.count > rhs.count : lhs.card.id < rhs.card.id
            }

        // Suit distribution, in canonical suit order.
        s.suitDistribution = Suit.allCases.map { suit in
            SuitSlice(id: suit.rawValue, suit: suit, count: suitCounts[suit] ?? 0)
        }

        s.perMonth = readingsPerMonth(readings)
        return s
    }

    /// Consecutive days (ending today or yesterday) that have at least one reading.
    static func currentStreak(_ readings: [Reading]) -> Int {
        guard !readings.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(readings.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = cal.startOfDay(for: .now)

        // Allow the streak to "start" today or yesterday.
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Readings per month for the last 6 months (oldest → newest), for Charts.
    static func readingsPerMonth(_ readings: [Reading]) -> [MonthCount] {
        let cal = Calendar.current
        let now = Date.now
        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "en_US_POSIX")
        monthFmt.dateFormat = "MMM"
        let keyFmt = DateFormatter()
        keyFmt.locale = Locale(identifier: "en_US_POSIX")
        keyFmt.dateFormat = "yyyy-MM"

        // Build the last 6 month buckets in order.
        var buckets: [MonthCount] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now),
                  let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthDate))
            else { continue }
            let key = keyFmt.string(from: firstOfMonth)
            let count = readings.filter { keyFmt.string(from: $0.date) == key }.count
            buckets.append(MonthCount(id: key, date: firstOfMonth, label: monthFmt.string(from: firstOfMonth), count: count))
        }
        return buckets
    }
}
