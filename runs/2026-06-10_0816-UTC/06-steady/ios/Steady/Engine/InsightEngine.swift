import Foundation

struct DayMood: Identifiable {
    let day: Date
    let score: Double?     // nil = no data that day
    var id: Date { day }
}

struct DistortionCount: Identifiable {
    let distortion: Distortion
    let count: Int
    var id: String { distortion.id }
}

struct SteadyInsights {
    let recordCount: Int
    let avgBeliefDrop: Double
    let avgIntensityDrop: Double
    let streak: Int
    let topDistortions: [DistortionCount]
    let moodTrend: [DayMood]          // last 30 days, mood logs + record emotions
    let totalReframes: Int
}

/// Pure aggregation over thought records and mood logs.
enum InsightEngine {

    static func compute(records: [ThoughtRecord], moods: [MoodLog],
                        calendar: Calendar = .current, now: Date = .now) -> SteadyInsights {
        let complete = records.filter(\.isComplete)
        let beliefDrops = complete.map { Double($0.beliefDrop) }
        let intensityDrops = complete.map { Double($0.intensityDrop) }

        // Distortion frequency.
        var counts: [String: Int] = [:]
        for r in records {
            for id in r.distortionIDs { counts[id, default: 0] += 1 }
        }
        let top = counts.compactMap { (id, n) -> DistortionCount? in
            guard let d = Distortions.named(id) else { return nil }
            return DistortionCount(distortion: d, count: n)
        }.sorted { $0.count > $1.count }

        // Streak of days with any activity (record or mood log).
        var activeDays = Set(records.map { calendar.startOfDay(for: $0.createdAt) })
        activeDays.formUnion(moods.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        if !activeDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while activeDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // Mood trend over 30 days: average of mood logs (1–5) plus a derived
        // 1–5 score from each record's post-reframe top emotion (inverted).
        var perDay: [Date: [Double]] = [:]
        for m in moods {
            let day = calendar.startOfDay(for: m.date)
            perDay[day, default: []].append(Double(m.score))
        }
        for r in complete {
            let day = calendar.startOfDay(for: r.createdAt)
            if let after = r.emotionsAfter.max(by: { $0.intensity < $1.intensity }) {
                // 0 intensity → 5 (great), 100 → 1 (very low)
                let score = 5.0 - (Double(after.intensity) / 100.0) * 4.0
                perDay[day, default: []].append(score)
            }
        }
        var trend: [DayMood] = []
        let today = calendar.startOfDay(for: now)
        for back in stride(from: 29, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { continue }
            if let values = perDay[day], !values.isEmpty {
                trend.append(DayMood(day: day, score: values.reduce(0, +) / Double(values.count)))
            } else {
                trend.append(DayMood(day: day, score: nil))
            }
        }

        return SteadyInsights(
            recordCount: complete.count,
            avgBeliefDrop: beliefDrops.isEmpty ? 0 : beliefDrops.reduce(0, +) / Double(beliefDrops.count),
            avgIntensityDrop: intensityDrops.isEmpty ? 0 : intensityDrops.reduce(0, +) / Double(intensityDrops.count),
            streak: streak,
            topDistortions: top,
            moodTrend: trend,
            totalReframes: complete.count
        )
    }
}
