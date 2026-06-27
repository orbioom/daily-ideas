import Foundation

struct TrainingStats {
    let totalSessions: Int
    let totalMinutes: Int
    let totalRounds: Int
    let streak: Int
    let weekMinutes: Int
    let avgIntensity: Double
    let sessionTypeDistribution: [(SessionType, Int)]
}

struct WeekBucket: Identifiable {
    let id: String
    let weekStart: Date
    let minutes: Int
    let sessions: Int
}

enum TrainingEngine {
    static func stats(from sessions: [TrainingSession]) -> TrainingStats {
        let totalMin = sessions.reduce(0) { $0 + $1.durationMinutes }
        let totalRounds = sessions.reduce(0) { $0 + $1.rounds }
        let avgIntensity = sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.intensityRaw }) / Double(sessions.count)
        let dist = sessionTypeDistribution(from: sessions)
        let streak = currentStreak(from: sessions)
        let weekStart = Calendar.current.startOfWeek(Date())
        let weekMin = sessions.filter { $0.date >= weekStart }.reduce(0) { $0 + $1.durationMinutes }
        return TrainingStats(
            totalSessions: sessions.count,
            totalMinutes: totalMin,
            totalRounds: totalRounds,
            streak: streak,
            weekMinutes: weekMin,
            avgIntensity: avgIntensity,
            sessionTypeDistribution: dist
        )
    }

    static func sessionTypeDistribution(from sessions: [TrainingSession]) -> [(SessionType, Int)] {
        let grouped = Dictionary(grouping: sessions, by: { $0.sessionType })
        return SessionType.allCases.compactMap { t in
            let count = grouped[t]?.count ?? 0
            return count > 0 ? (t, count) : nil
        }.sorted { $0.1 > $1.1 }
    }

    static func currentStreak(from sessions: [TrainingSession]) -> Int {
        let sorted = sessions.sorted { $0.date > $1.date }
        let cal = Calendar.current
        var count = 0
        var check = cal.startOfDay(Date())
        for s in sorted {
            let day = cal.startOfDay(s.date)
            if day == check { count += 1; continue }
            guard let prev = cal.date(byAdding: .day, value: -1, to: check), day == prev else { break }
            count += 1
            check = prev
        }
        return count
    }

    static func weeklyBuckets(from sessions: [TrainingSession], count: Int = 8) -> [WeekBucket] {
        let cal = Calendar.current
        let now = Date()
        let fmt = DateFormatter(); fmt.dateFormat = "MM/dd"
        return (0..<count).reversed().map { offset -> WeekBucket in
            let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: cal.startOfWeek(now)) ?? now
            let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? now
            let bucket = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
            return WeekBucket(
                id: fmt.string(from: weekStart),
                weekStart: weekStart,
                minutes: bucket.reduce(0) { $0 + $1.durationMinutes },
                sessions: bucket.count
            )
        }
    }
}

private extension Calendar {
    func startOfWeek(_ date: Date) -> Date {
        var comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2
        return self.date(from: comps) ?? date
    }
}
