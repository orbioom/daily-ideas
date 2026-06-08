import Foundation

/// Pure analysis over mood entries: trend, averages, streak, and the headline
/// feature — which activities correlate with feeling better or worse.
struct MoodInsights {
    let entryCount: Int
    let average: Double
    let streakDays: Int
    let trend: [DayPoint]
    let correlations: [ActivityImpact]
    let distribution: [Int: Int]   // mood level -> count

    struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let average: Double
        let count: Int
    }

    struct ActivityImpact: Identifiable {
        let id: UUID
        let name: String
        let symbol: String
        let withActivity: Double   // average mood when present
        let delta: Double          // vs overall average
        let sampleSize: Int
    }

    static func make(entries: [MoodEntry],
                     activities: [Activity],
                     days: Int = 30,
                     calendar: Calendar = .current,
                     now: Date = .now) -> MoodInsights {
        let moods = entries.map { Double($0.mood) }
        let overall = moods.isEmpty ? 0 : moods.reduce(0, +) / Double(moods.count)

        // Streak of consecutive days with at least one entry.
        let daysWithEntry = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var day = calendar.startOfDay(for: now)
        if !daysWithEntry.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while daysWithEntry.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        // Daily averages for the trend window.
        var trend: [DayPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let d = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else { continue }
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: d) }
            let avg = dayEntries.isEmpty ? 0 : dayEntries.map { Double($0.mood) }.reduce(0, +) / Double(dayEntries.count)
            trend.append(DayPoint(date: d, average: avg, count: dayEntries.count))
        }

        // Activity correlations.
        var impacts: [ActivityImpact] = []
        for activity in activities where !activity.isArchived {
            let related = entries.filter { entry in
                entry.activities.contains { $0.id == activity.id }
            }
            guard related.count >= 2 else { continue }
            let avg = related.map { Double($0.mood) }.reduce(0, +) / Double(related.count)
            impacts.append(ActivityImpact(id: activity.id,
                                          name: activity.name,
                                          symbol: activity.symbol,
                                          withActivity: avg,
                                          delta: avg - overall,
                                          sampleSize: related.count))
        }
        impacts.sort { abs($0.delta) > abs($1.delta) }

        // Distribution.
        var dist: [Int: Int] = [:]
        for level in 1...5 { dist[level] = entries.filter { $0.mood == level }.count }

        return MoodInsights(entryCount: entries.count,
                            average: overall,
                            streakDays: streak,
                            trend: trend,
                            correlations: impacts,
                            distribution: dist)
    }
}
