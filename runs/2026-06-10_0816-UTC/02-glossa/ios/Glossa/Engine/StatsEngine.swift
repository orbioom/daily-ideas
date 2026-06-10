import Foundation

struct DayCount: Identifiable {
    let day: Date
    let count: Int
    var id: Date { day }
}

struct GlossaStats {
    let streak: Int
    let totalReviews: Int
    let accuracy: Double          // 0...1 over all sessions
    let reviewsPerDay: [DayCount] // last 14 days
    let masteredTotal: Int
    let cardTotal: Int
    let boxDistribution: [Int]    // index 0 = box 1
}

enum StatsEngine {

    static func compute(sessions: [ReviewSession], decks: [Deck],
                        calendar: Calendar = .current, now: Date = .now) -> GlossaStats {
        let correct = sessions.reduce(0) { $0 + $1.correct }
        let missed = sessions.reduce(0) { $0 + $1.missed }
        let total = correct + missed

        // Streak: consecutive days with at least one session, ending today or yesterday.
        let studyDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        if !studyDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while studyDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // Reviews per day, last 14 days.
        var perDay: [DayCount] = []
        let today = calendar.startOfDay(for: now)
        for back in stride(from: 13, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -back, to: today),
                  let next = calendar.date(byAdding: .day, value: 1, to: day) else { continue }
            let n = sessions.filter { $0.date >= day && $0.date < next }
                .reduce(0) { $0 + $1.correct + $1.missed }
            perDay.append(DayCount(day: day, count: n))
        }

        var boxes = [Int](repeating: 0, count: LeitnerEngine.boxCount)
        var mastered = 0
        var cardTotal = 0
        for deck in decks {
            for card in deck.cards {
                cardTotal += 1
                let b = min(max(card.box, 1), LeitnerEngine.boxCount)
                boxes[b - 1] += 1
                if b == LeitnerEngine.boxCount { mastered += 1 }
            }
        }

        return GlossaStats(
            streak: streak,
            totalReviews: total,
            accuracy: total == 0 ? 0 : Double(correct) / Double(total),
            reviewsPerDay: perDay,
            masteredTotal: mastered,
            cardTotal: cardTotal,
            boxDistribution: boxes
        )
    }
}
