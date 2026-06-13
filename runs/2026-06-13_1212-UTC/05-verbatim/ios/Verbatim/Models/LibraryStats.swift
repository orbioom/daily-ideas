import Foundation

/// Aggregates over the whole library and its review history: streaks, totals,
/// mastery distribution, and a reviews-per-week series for the Progress screen.
struct LibraryStats {
    let reviewStreak: Int            // distinct review days in a row, ending today/yesterday
    let longestStreak: Int
    let passagesMastered: Int        // mastery level 5
    let wordsMemorized: Int          // sum of wordCount for level >= 4
    let totalReviews: Int
    let masteryDistribution: [Int]   // index 0...5 → count of passages at that level
    let weeklySeries: [WeekBucket]   // reviews per ISO week, oldest → newest

    struct WeekBucket: Identifiable {
        let id = UUID()
        let weekStart: Date
        let count: Int
    }

    static func from(passages: [Passage], reviews: [ReviewLog], now: Date = .now) -> LibraryStats {
        let cal = Calendar.current

        // Mastery distribution (always 6 buckets, 0...5).
        var dist = Array(repeating: 0, count: 6)
        for p in passages {
            let lvl = min(max(p.masteryLevel, 0), 5)
            dist[lvl] += 1
        }

        let mastered = passages.filter { $0.isMastered }.count
        let words = passages.filter { $0.masteryLevel >= 4 }.reduce(0) { $0 + $1.wordCount }

        // Streak over distinct review days.
        let days = Set(reviews.map { cal.startOfDay(for: $0.date) }).sorted()
        var longest = 0, run = 0
        var prev: Date?
        for d in days {
            if let p = prev, cal.dateComponents([.day], from: p, to: d).day == 1 { run += 1 }
            else { run = 1 }
            longest = max(longest, run)
            prev = d
        }
        var current = 0
        if let last = days.last {
            let gap = cal.dateComponents([.day], from: last, to: cal.startOfDay(for: now)).day ?? 99
            if gap <= 1 {
                current = 1
                var cursor = last
                while let p = cal.date(byAdding: .day, value: -1, to: cursor),
                      days.contains(p) { current += 1; cursor = p }
            }
        }

        // Reviews per week for the last 8 weeks.
        let series = weeklySeries(reviews: reviews, now: now, weeks: 8, calendar: cal)

        return LibraryStats(
            reviewStreak: current,
            longestStreak: longest,
            passagesMastered: mastered,
            wordsMemorized: words,
            totalReviews: reviews.count,
            masteryDistribution: dist,
            weeklySeries: series)
    }

    private static func weeklySeries(reviews: [ReviewLog], now: Date,
                                     weeks: Int, calendar cal: Calendar) -> [WeekBucket] {
        guard weeks > 0 else { return [] }
        // Anchor each review to the start of its week.
        func weekStart(_ date: Date) -> Date {
            cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
        }
        var counts: [Date: Int] = [:]
        for r in reviews { counts[weekStart(r.date), default: 0] += 1 }

        var buckets: [WeekBucket] = []
        let thisWeek = weekStart(now)
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let start = cal.date(byAdding: .weekOfYear, value: -offset, to: thisWeek) else { continue }
            buckets.append(WeekBucket(weekStart: start, count: counts[start] ?? 0))
        }
        return buckets
    }
}
