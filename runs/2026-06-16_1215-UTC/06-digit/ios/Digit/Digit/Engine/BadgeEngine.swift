import Foundation

struct Badge: Identifiable {
    let id: String
    let title: String
    let detail: String
    let emoji: String
    let earned: Bool
    /// 0...1 progress toward earning (1 when earned).
    let progress: Double
}

/// Computes earned & in-progress badges from a profile's facts + sessions. Pure & guarded.
enum BadgeEngine {

    static func badges(facts: [FactStat], sessions: [Session]) -> [Badge] {
        let mastered = ProgressEngine.totalMastered(facts: facts)
        let streak = ProgressEngine.dayStreak(sessions: sessions)
        let totalSessions = sessions.count
        let totalStars = ProgressEngine.totalStars(sessions: sessions)
        let speeds = facts.compactMap { $0.fastestMs }
        let hasSpeedDemon = speeds.contains { $0 <= 2_000 }
        let perfectRounds = sessions.filter { $0.total > 0 && $0.correct == $0.total }.count

        // ×5 table mastered: all ×5 facts (5×1...5×12 either orientation) at mastery 3.
        let fiveTable = facts.filter { $0.op == .mul && ($0.a == 5 || $0.b == 5) }
        let fiveMastered = !fiveTable.isEmpty && fiveTable.allSatisfy { $0.masteryLevel >= 3 }
        let fiveProgress = fiveTable.isEmpty ? 0 :
            Double(fiveTable.filter { $0.masteryLevel >= 3 }.count) / Double(fiveTable.count)

        func frac(_ value: Int, _ goal: Int) -> Double {
            guard goal > 0 else { return 0 }
            return min(1, Double(value) / Double(goal))
        }

        return [
            Badge(id: "first10", title: "First 10 facts!",
                  detail: "Master your first 10 number facts.",
                  emoji: "🎉", earned: mastered >= 10, progress: frac(mastered, 10)),
            Badge(id: "first25", title: "Fact Collector",
                  detail: "Master 25 number facts.",
                  emoji: "📚", earned: mastered >= 25, progress: frac(mastered, 25)),
            Badge(id: "streak5", title: "5-day streak",
                  detail: "Practice 5 days in a row.",
                  emoji: "🔥", earned: streak >= 5, progress: frac(streak, 5)),
            Badge(id: "streak10", title: "On Fire",
                  detail: "Keep a 10-day practice streak.",
                  emoji: "⚡️", earned: streak >= 10, progress: frac(streak, 10)),
            Badge(id: "five_table", title: "×5 table mastered",
                  detail: "Master every fact in the 5 times table.",
                  emoji: "🖐️", earned: fiveMastered, progress: fiveProgress),
            Badge(id: "speed", title: "Speed demon",
                  detail: "Answer a fact in under 2 seconds.",
                  emoji: "🏎️", earned: hasSpeedDemon,
                  progress: hasSpeedDemon ? 1 : 0),
            Badge(id: "perfect", title: "Flawless round",
                  detail: "Get every question right in a round.",
                  emoji: "💯", earned: perfectRounds >= 1,
                  progress: perfectRounds >= 1 ? 1 : 0),
            Badge(id: "stars50", title: "Star jar",
                  detail: "Collect 50 stars from practice.",
                  emoji: "⭐️", earned: totalStars >= 50, progress: frac(totalStars, 50)),
            Badge(id: "sessions20", title: "Dedicated",
                  detail: "Finish 20 practice rounds.",
                  emoji: "🎯", earned: totalSessions >= 20, progress: frac(totalSessions, 20))
        ]
    }

    static func earnedCount(_ badges: [Badge]) -> Int { badges.filter { $0.earned }.count }
}
