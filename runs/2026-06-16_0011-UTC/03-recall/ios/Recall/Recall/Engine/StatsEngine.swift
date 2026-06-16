import Foundation

/// One day's review tally for the activity chart.
struct DayReviews: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

/// One day's forecast of cards coming due.
struct ForecastDay: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let count: Int
}

/// One maturity slice for the donut chart.
struct MaturitySlice: Identifiable {
    let id = UUID()
    let maturity: Maturity
    let count: Int
}

/// The computed Stats payload.
struct StatsResult {
    var totalCards: Int
    var totalDecks: Int
    var dueToday: Int
    var reviewsLast30: [DayReviews]
    var forecastNext14: [ForecastDay]
    var maturityMix: [MaturitySlice]
    var retentionPercent: Int      // % of graded reviews that were not "Again"
    var totalReviews: Int
    var streakDays: Int
    var matureCount: Int

    var isEmpty: Bool { totalCards == 0 && totalReviews == 0 }
}

/// Pure computations for the Stats screen. No SwiftData fetches; takes snapshots.
enum StatsEngine {

    static func compute(cards: [Card],
                        logs: [ReviewLog],
                        deckCount: Int,
                        now: Date = .now,
                        calendar: Calendar = .current) -> StatsResult {
        let active = cards.filter { !$0.isSuspended }

        let due = StudyQueue.dueCount(in: active, now: now)
        let reviews30 = reviewsPerDay(logs: logs, days: 30, now: now, calendar: calendar)
        let forecast = forecast(cards: active, days: 14, now: now, calendar: calendar)
        let maturity = maturityMix(cards: active)
        let retention = retentionPercent(logs: logs)
        let streak = streak(logs: logs, now: now, calendar: calendar)
        let mature = active.filter { $0.maturity == .mature }.count

        return StatsResult(totalCards: active.count,
                           totalDecks: deckCount,
                           dueToday: due,
                           reviewsLast30: reviews30,
                           forecastNext14: forecast,
                           maturityMix: maturity,
                           retentionPercent: retention,
                           totalReviews: logs.count,
                           streakDays: streak,
                           matureCount: mature)
    }

    /// Reviews counted per calendar day for the last `days` days (oldest first).
    static func reviewsPerDay(logs: [ReviewLog],
                              days: Int,
                              now: Date = .now,
                              calendar: Calendar = .current) -> [DayReviews] {
        let span = max(1, days)
        let today = calendar.startOfDay(for: now)
        var buckets: [Date: Int] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            buckets[day, default: 0] += 1
        }
        var out: [DayReviews] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            out.append(DayReviews(date: day, count: buckets[day] ?? 0))
        }
        return out
    }

    /// Count of cards becoming due on each of the next `days` days (incl. today).
    static func forecast(cards: [Card],
                         days: Int,
                         now: Date = .now,
                         calendar: Calendar = .current) -> [ForecastDay] {
        let span = max(1, days)
        let today = calendar.startOfDay(for: now)
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.dateFormat = "E"
        var out: [ForecastDay] = []
        for offset in 0..<span {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            let count = cards.filter { card in
                guard !card.isNew else { return false }
                let due = calendar.startOfDay(for: card.dueDate)
                if offset == 0 {
                    // "Today" absorbs anything overdue too.
                    return card.dueDate < nextDay
                }
                return due >= day && due < nextDay
            }.count
            let label = offset == 0 ? "Today" : fmt.string(from: day)
            out.append(ForecastDay(date: day, label: label, count: count))
        }
        return out
    }

    /// Card counts grouped by maturity (always returns all four buckets).
    static func maturityMix(cards: [Card]) -> [MaturitySlice] {
        Maturity.allCases.map { m in
            MaturitySlice(maturity: m, count: cards.filter { $0.maturity == m }.count)
        }
    }

    /// Percentage of graded reviews that were *not* "Again".
    static func retentionPercent(logs: [ReviewLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let correct = logs.filter { $0.grade.isCorrect }.count
        let pct = Double(correct) / Double(logs.count) * 100
        return Int(pct.rounded())
    }

    /// Consecutive days (ending today or yesterday) with at least one review.
    static func streak(logs: [ReviewLog],
                       now: Date = .now,
                       calendar: Calendar = .current) -> Int {
        guard !logs.isEmpty else { return 0 }
        let reviewedDays = Set(logs.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: now)
        // Allow the streak to count if today has no review yet but yesterday did.
        var anchor = today
        if !reviewedDays.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  reviewedDays.contains(yesterday) else { return 0 }
            anchor = yesterday
        }
        var count = 0
        var cursor = anchor
        while reviewedDays.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}
