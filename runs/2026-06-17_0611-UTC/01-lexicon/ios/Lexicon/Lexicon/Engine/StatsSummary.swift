import Foundation

/// Computed, division-guarded summary of all GameResults. Streaks are based on the
/// daily puzzle: consecutive calendar days with a won daily game, ending today or
/// yesterday (so the streak doesn't break until a day is fully missed).
struct StatsSummary {
    var played: Int
    var wins: Int
    var winPercent: Int
    var currentStreak: Int
    var maxStreak: Int
    /// Index 0 => won in 1 guess … index maxGuesses-1 => won in maxGuesses.
    var guessDistribution: [Int]

    static let empty = StatsSummary(
        played: 0, wins: 0, winPercent: 0,
        currentStreak: 0, maxStreak: 0,
        guessDistribution: Array(repeating: 0, count: DailyPuzzle.maxGuesses)
    )

    var isEmpty: Bool { played == 0 }

    /// Build a summary from results. `calendar` lets tests inject a fixed calendar.
    static func make(from results: [GameResult], today: Date = .now, calendar: Calendar = .current) -> StatsSummary {
        guard !results.isEmpty else { return .empty }

        let played = results.count
        let wins = results.filter { $0.won }.count
        let winPercent = played > 0 ? Int((Double(wins) / Double(played) * 100).rounded()) : 0

        // Guess distribution over wins only.
        var dist = Array(repeating: 0, count: DailyPuzzle.maxGuesses)
        for r in results where r.won {
            let idx = r.guessCount - 1
            if idx >= 0 && idx < dist.count {
                dist[idx] += 1
            }
        }

        // Streaks from daily wins keyed by calendar day.
        let dailyWonDays: Set<Date> = Set(
            results
                .filter { $0.gameMode == .daily && $0.won }
                .map { calendar.startOfDay(for: $0.date) }
        )
        let (current, maxStreak) = streaks(from: dailyWonDays, today: today, calendar: calendar)

        return StatsSummary(
            played: played,
            wins: wins,
            winPercent: winPercent,
            currentStreak: current,
            maxStreak: maxStreak,
            guessDistribution: dist
        )
    }

    private static func streaks(from wonDays: Set<Date>, today: Date, calendar: Calendar) -> (current: Int, max: Int) {
        guard !wonDays.isEmpty else { return (0, 0) }
        let sorted = wonDays.sorted()

        // Max streak: longest run of consecutive days.
        var maxRun = 1
        var run = 1
        for i in 1..<sorted.count {
            if let prevNext = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               calendar.isDate(prevNext, inSameDayAs: sorted[i]) {
                run += 1
            } else {
                run = 1
            }
            maxRun = Swift.max(maxRun, run)
        }

        // Current streak: count back from today (or yesterday) while days are present.
        let startOfToday = calendar.startOfDay(for: today)
        var anchor: Date? = nil
        if wonDays.contains(startOfToday) {
            anchor = startOfToday
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
                  wonDays.contains(yesterday) {
            anchor = yesterday
        }

        var current = 0
        if var day = anchor {
            while wonDays.contains(day) {
                current += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            }
        }

        return (current, maxRun)
    }
}
