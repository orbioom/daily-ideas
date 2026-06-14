import Foundation

/// Lightweight current-streak computation shared by Today and Stats, kept
/// separate from the heavier StatsEngine so the hero card stays cheap.
enum StreakService {
    /// Current daily-solve streak from a set of solved yyyy-MM-dd keys.
    static func currentStreak(solvedKeys: Set<String>) -> Int {
        guard !solvedKeys.isEmpty else { return 0 }
        let cal = Calendar(identifier: .gregorian)
        let todayStart = cal.startOfDay(for: .now)
        let solvedDays: Set<Date> = Set(solvedKeys.compactMap { key in
            DateKey.date(from: key).map { cal.startOfDay(for: $0) }
        })

        var cursor = todayStart
        if !solvedDays.contains(todayStart) {
            // Allow the streak to "hold" if yesterday was solved.
            cursor = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
            if !solvedDays.contains(cursor) { return 0 }
        }
        var count = 0
        while solvedDays.contains(cursor) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}
