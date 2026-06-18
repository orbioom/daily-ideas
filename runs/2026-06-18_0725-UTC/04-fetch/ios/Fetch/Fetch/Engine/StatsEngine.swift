import Foundation

/// Aggregated, chart-ready data points. Pure and guarded.
enum StatsEngine {

    struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let sessions: Int
        let minutes: Int
    }

    struct CategoryPoint: Identifiable {
        let id = UUID()
        let category: TrickCategory
        let mastered: Int
        let total: Int
        var fraction: Double {
            guard total > 0 else { return 0 }
            return min(1, Double(mastered) / Double(total))
        }
    }

    struct RatingPoint: Identifiable {
        let id = UUID()
        let rating: Int
        let count: Int
    }

    /// Sessions and minutes per day across the last `days` days (inclusive of today).
    static func daily(for dog: Dog, days: Int = 30, now: Date = Date()) -> [DayPoint] {
        let cal = Calendar.current
        let span = max(1, days)
        let today = cal.startOfDay(for: now)

        // Pre-build buckets so empty days still render.
        var buckets: [Date: (sessions: Int, minutes: Int)] = [:]
        for offset in stride(from: span - 1, through: 0, by: -1) {
            if let d = cal.date(byAdding: .day, value: -offset, to: today) {
                buckets[d] = (0, 0)
            }
        }

        for session in dog.sessions {
            let day = cal.startOfDay(for: session.date)
            if buckets[day] != nil {
                buckets[day]?.sessions += 1
                buckets[day]?.minutes += session.durationSec / 60
            }
        }

        return buckets
            .map { DayPoint(date: $0.key, sessions: $0.value.sessions, minutes: $0.value.minutes) }
            .sorted { $0.date < $1.date }
    }

    static func byCategory(for dog: Dog) -> [CategoryPoint] {
        TrickCategory.allCases.map { cat in
            let tricks = TrickCatalog.tricks(in: cat)
            let total = tricks.count
            let mastered = tricks.filter { trick in
                ProgressEngine.status(for: dog, trickId: trick.id) == .mastered
            }.count
            return CategoryPoint(category: cat, mastered: mastered, total: total)
        }
    }

    static func ratings(for dog: Dog) -> [RatingPoint] {
        var counts: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for s in dog.sessions {
            let r = min(5, max(1, s.successRating))
            counts[r, default: 0] += 1
        }
        return (1...5).map { RatingPoint(rating: $0, count: counts[$0] ?? 0) }
    }

    static func totalMinutes(for dog: Dog) -> Int {
        dog.sessions.reduce(0) { $0 + $1.durationSec } / 60
    }

    static func totalSessions(for dog: Dog) -> Int {
        dog.sessions.count
    }

    static func totalReps(for dog: Dog) -> Int {
        dog.sessions.reduce(0) { $0 + $1.reps }
    }

    static func averageRating(for dog: Dog) -> Double {
        guard !dog.sessions.isEmpty else { return 0 }
        let sum = dog.sessions.reduce(0) { $0 + min(5, max(1, $1.successRating)) }
        return Double(sum) / Double(dog.sessions.count)
    }
}
