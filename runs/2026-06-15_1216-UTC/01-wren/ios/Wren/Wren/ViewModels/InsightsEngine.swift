import Foundation

/// Pure aggregation for the Insights screen. Takes model values, returns chart-ready
/// structs. No SwiftUI / SwiftData imports.
enum InsightsEngine {

    struct DayCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    struct MoodPoint: Identifiable {
        let id = UUID()
        let date: Date
        let mood: Double
    }

    struct CategorySlice: Identifiable {
        let id = UUID()
        let category: GoalCategory
        let count: Int
    }

    struct XPPoint: Identifiable {
        let id = UUID()
        let date: Date
        let cumulativeXP: Int
        let level: Int
    }

    /// Completions per day for the last `days` days (oldest → newest).
    static func completionsByDay(_ completions: [GoalCompletion], days: Int = 14, now: Date = Date()) -> [DayCount] {
        let today = DateUtils.startOfDay(now)
        var buckets: [Date: Int] = [:]
        for c in completions {
            let day = DateUtils.startOfDay(c.date)
            if DateUtils.daysBetween(day, today) < days {
                buckets[day, default: 0] += 1
            }
        }
        return (0..<days).reversed().map { offset in
            let day = DateUtils.adding(days: -offset, to: today)
            return DayCount(date: DateUtils.startOfDay(day), count: buckets[DateUtils.startOfDay(day)] ?? 0)
        }
    }

    /// Mood trend over the last `days` days where a check-in exists.
    static func moodTrend(_ checkIns: [CheckIn], days: Int = 14, now: Date = Date()) -> [MoodPoint] {
        let today = DateUtils.startOfDay(now)
        return checkIns
            .filter { DateUtils.daysBetween(DateUtils.startOfDay($0.date), today) < days }
            .sorted { $0.date < $1.date }
            .map { MoodPoint(date: DateUtils.startOfDay($0.date), mood: Double($0.mood)) }
    }

    /// Completion count by category across the provided completions.
    static func categoryBalance(_ completions: [GoalCompletion]) -> [CategorySlice] {
        var counts: [GoalCategory: Int] = [:]
        for c in completions {
            guard let cat = c.goal?.category else { continue }
            counts[cat, default: 0] += 1
        }
        return GoalCategory.allCases.compactMap { cat in
            let n = counts[cat] ?? 0
            return n > 0 ? CategorySlice(category: cat, count: n) : nil
        }
    }

    /// Cumulative XP & level over the last `days` days from completion energy/XP.
    static func xpOverTime(_ completions: [GoalCompletion], days: Int = 30, now: Date = Date()) -> [XPPoint] {
        let today = DateUtils.startOfDay(now)
        // Group XP contribution by day (xp == energyAwarded by engine rule).
        var perDay: [Date: Int] = [:]
        for c in completions {
            let day = DateUtils.startOfDay(c.date)
            perDay[day, default: 0] += max(1, c.energyAwarded)
        }
        // Build cumulative from earliest seen day, but only emit the trailing window.
        let allDays = perDay.keys.sorted()
        guard let earliest = allDays.first else { return [] }
        var cumulative = 0
        var points: [XPPoint] = []
        var cursor = earliest
        while cursor <= today {
            cumulative += perDay[cursor] ?? 0
            if DateUtils.daysBetween(cursor, today) < days {
                let lvl = CareEngine.levelProgress(totalXP: cumulative).level
                points.append(XPPoint(date: cursor, cumulativeXP: cumulative, level: lvl))
            }
            cursor = DateUtils.adding(days: 1, to: cursor)
        }
        return points
    }

    /// Overall completion rate across the provided distinct completion days within window.
    static func completionRate(_ completions: [GoalCompletion], window: Int = 30, now: Date = Date()) -> Double {
        let days = Set(completions.map { DateUtils.startOfDay($0.date) })
        return CareEngine.completionRate(completionDays: days, window: window, now: now)
    }
}
