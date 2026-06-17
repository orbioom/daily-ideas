import Foundation

/// Aggregate stats computed from saved readings and daily draws. Pure functions — easy to test.
enum StatsEngine {
    struct CardCount: Identifiable {
        let card: TarotCard
        let count: Int
        var id: Int { card.id }
    }

    struct SuitSlice: Identifiable {
        let suit: Suit
        let count: Int
        var id: String { suit.rawValue }
    }

    struct ArcanaSlice: Identifiable {
        let arcana: Arcana
        let count: Int
        var id: String { arcana.rawValue }
    }

    struct DayCount: Identifiable {
        let day: Date
        let count: Int
        var id: Date { day }
    }

    /// Flatten every drawn card across readings and daily draws into (cardId, ...) pairs.
    static func allCardIds(readings: [Reading], dailies: [DailyDraw]) -> [Int] {
        var ids: [Int] = []
        for r in readings { for c in r.cards { ids.append(c.cardId) } }
        for d in dailies { ids.append(d.cardId) }
        return ids
    }

    static func totalDraws(readings: [Reading], dailies: [DailyDraw]) -> Int {
        allCardIds(readings: readings, dailies: dailies).count
    }

    /// Most-drawn cards, descending. `limit` caps the result.
    static func mostDrawn(readings: [Reading], dailies: [DailyDraw], limit: Int = 5) -> [CardCount] {
        var counts: [Int: Int] = [:]
        for id in allCardIds(readings: readings, dailies: dailies) {
            counts[id, default: 0] += 1
        }
        return counts.compactMap { (id, n) -> CardCount? in
            guard let card = Deck.card(id: id) else { return nil }
            return CardCount(card: card, count: n)
        }
        .sorted { $0.count > $1.count || ($0.count == $1.count && $0.card.id < $1.card.id) }
        .prefix(limit)
        .map { $0 }
    }

    /// Distribution across the four suits (Minor only).
    static func suitDistribution(readings: [Reading], dailies: [DailyDraw]) -> [SuitSlice] {
        var counts: [Suit: Int] = [:]
        for id in allCardIds(readings: readings, dailies: dailies) {
            if let suit = Deck.card(id: id)?.suit {
                counts[suit, default: 0] += 1
            }
        }
        return Suit.allCases.map { SuitSlice(suit: $0, count: counts[$0] ?? 0) }
    }

    /// Major vs Minor split.
    static func arcanaDistribution(readings: [Reading], dailies: [DailyDraw]) -> [ArcanaSlice] {
        var counts: [Arcana: Int] = [:]
        for id in allCardIds(readings: readings, dailies: dailies) {
            if let a = Deck.card(id: id)?.arcana {
                counts[a, default: 0] += 1
            }
        }
        return Arcana.allCases.map { ArcanaSlice(arcana: $0, count: counts[$0] ?? 0) }
    }

    /// Readings (saved spreads) over the last `days` days, oldest first.
    static func readingsOverTime(readings: [Reading], dailies: [DailyDraw], days: Int = 14) -> [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var perDay: [Date: Int] = [:]
        let events: [Date] = readings.map { $0.date } + dailies.map { $0.date }
        for date in events {
            let day = cal.startOfDay(for: date)
            perDay[day, default: 0] += 1
        }
        var out: [DayCount] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                out.append(DayCount(day: day, count: perDay[day] ?? 0))
            }
        }
        return out
    }

    /// Current consecutive-day journaling streak based on daily draws (today or yesterday anchors it).
    static func currentStreak(dailies: [DailyDraw]) -> Int {
        let cal = Calendar.current
        let days = Set(dailies.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        let today = cal.startOfDay(for: .now)
        var cursor = today
        // Allow the streak to be "alive" if today isn't drawn yet but yesterday was.
        if !days.contains(today) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
