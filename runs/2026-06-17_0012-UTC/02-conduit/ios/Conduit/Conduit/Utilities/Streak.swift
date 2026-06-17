import Foundation

/// Computes current and best daily streaks from a set of solved day-keys.
enum Streak {

    /// Parse a "yyyy-MM-dd" key into a calendar date (start of that day).
    private static func date(from key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[safe: 0] ?? ""),
              let m = Int(parts[safe: 1] ?? ""),
              let d = Int(parts[safe: 2] ?? "") else { return nil }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        return Calendar.current.date(from: comps)
    }

    /// Days between two dates (ignoring time of day).
    private static func dayGap(_ a: Date, _ b: Date) -> Int {
        let cal = Calendar.current
        let da = cal.startOfDay(for: a)
        let db = cal.startOfDay(for: b)
        return cal.dateComponents([.day], from: da, to: db).day ?? Int.max
    }

    /// Current streak counting back from today (or yesterday if today not yet solved).
    static func current(solvedKeys: [String], today: Date = .now) -> Int {
        let dates = solvedKeys.compactMap { date(from: $0) }
            .map { Calendar.current.startOfDay(for: $0) }
        let set = Set(dates)
        guard !set.isEmpty else { return 0 }

        let cal = Calendar.current
        var streak = 0
        var cursor = cal.startOfDay(for: today)

        // If today isn't solved, the streak may still be alive if yesterday was.
        if !set.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  set.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        while set.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest run of consecutive solved days ever.
    static func best(solvedKeys: [String]) -> Int {
        let dates = solvedKeys.compactMap { date(from: $0) }
            .map { Calendar.current.startOfDay(for: $0) }
        let sorted = Array(Set(dates)).sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var run = 1
        for i in 1..<sorted.count {
            guard let a = sorted[safe: i - 1], let b = sorted[safe: i] else { continue }
            if dayGap(a, b) == 1 {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }
}
