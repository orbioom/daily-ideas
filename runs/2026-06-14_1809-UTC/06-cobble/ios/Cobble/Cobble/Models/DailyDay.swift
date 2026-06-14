import Foundation

/// A calendar day in the Daily archive. Hashable so it can be a NavigationStack value.
struct DailyDay: Identifiable, Hashable {
    let date: Date

    var id: String { dateKey }
    var dateKey: String { DailySeed.dateKey(for: date) }

    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var longLabel: String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// The last `count` days ending today, oldest first.
    static func lastDays(_ count: Int, from today: Date, calendar: Calendar = .current) -> [DailyDay] {
        guard count > 0 else { return [] }
        var days: [DailyDay] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            if let d = calendar.date(byAdding: .day, value: -offset, to: today) {
                days.append(DailyDay(date: d))
            }
        }
        return days
    }
}

/// Daily streak calculation from the set of played day keys.
enum DailyStreak {
    /// Count of consecutive played days ending at today (or yesterday, if today not yet
    /// played but the run is otherwise unbroken).
    static func current(playedDays: Set<String>, today: Date, calendar: Calendar = .current) -> Int {
        guard !playedDays.isEmpty else { return 0 }
        var streak = 0
        var cursor = today
        // If today isn't played, start counting from yesterday so an active streak shows.
        if !playedDays.contains(DailySeed.dateKey(for: cursor)) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = y
        }
        while playedDays.contains(DailySeed.dateKey(for: cursor)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
