import Foundation

/// A point on the accuracy-over-time line.
struct AccuracyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
    let label: String
}

/// Mastery aggregated by tense.
struct TenseMastery: Identifiable {
    let id = UUID()
    let tense: Tense
    let mastery: Double      // 0...1 average
    let label: String
}

/// Mastery aggregated by verb group.
struct GroupMastery: Identifiable {
    let id = UUID()
    let group: VerbGroup
    let mastery: Double
    let label: String
}

/// A weak verb to target.
struct WeakVerb: Identifiable {
    let id = UUID()
    let infinitive: String
    let tense: Tense
    let mastery: Double
    let attempts: Int
}

/// Computed statistics bundle.
struct StatsResult {
    var totalAttempts: Int = 0
    var overallAccuracy: Double = 0
    var masteredCount: Int = 0
    var streak: Int = 0
    var accuracyOverTime: [AccuracyPoint] = []
    var masteryByTense: [TenseMastery] = []
    var masteryByGroup: [GroupMastery] = []
    var weakVerbs: [WeakVerb] = []

    var isEmpty: Bool { totalAttempts == 0 && accuracyOverTime.isEmpty }
}

/// Pure statistics computation over snapshots of persisted data.
enum StatsEngine {

    static func compute(stats: [ItemStat],
                        sessions: [DrillSession],
                        language: Language) -> StatsResult {
        var result = StatsResult()
        let langStats = stats.filter { $0.language == language.rawValue }
        let langSessions = sessions.filter { $0.language == language.rawValue }

        // Totals.
        result.totalAttempts = langStats.reduce(0) { $0 + $1.attempts }
        let totalCorrect = langStats.reduce(0) { $0 + $1.correct }
        result.overallAccuracy = result.totalAttempts > 0
            ? Double(totalCorrect) / Double(result.totalAttempts)
            : 0
        result.masteredCount = langStats.filter { $0.isMastered }.count

        // Accuracy over time (one point per session, chronological).
        let sortedSessions = langSessions.sorted { $0.date < $1.date }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        result.accuracyOverTime = sortedSessions.map {
            AccuracyPoint(date: $0.date, accuracy: $0.accuracy, label: df.string(from: $0.date))
        }

        // Mastery by tense.
        var byTense: [Tense: [Double]] = [:]
        for s in langStats {
            guard let t = s.tenseEnum, s.attempts > 0 else { continue }
            byTense[t, default: []].append(s.mastery)
        }
        result.masteryByTense = language.tenses.compactMap { tense in
            guard let values = byTense[tense], !values.isEmpty else { return nil }
            let avg = values.reduce(0, +) / Double(values.count)
            return TenseMastery(tense: tense, mastery: avg, label: tense.displayName)
        }

        // Mastery by verb group.
        var byGroup: [VerbGroup: [Double]] = [:]
        for s in langStats where s.attempts > 0 {
            guard let verb = VerbCatalog.verb(infinitive: s.verbInfinitive, language: language) else { continue }
            byGroup[verb.group, default: []].append(s.mastery)
        }
        result.masteryByGroup = VerbGroup.allCases.compactMap { group in
            guard let values = byGroup[group], !values.isEmpty else { return nil }
            let avg = values.reduce(0, +) / Double(values.count)
            return GroupMastery(group: group, mastery: avg, label: group.displayName)
        }

        // Weakest verbs (lowest mastery, with at least one attempt).
        result.weakVerbs = langStats
            .filter { $0.attempts > 0 }
            .sorted { $0.mastery < $1.mastery }
            .prefix(8)
            .compactMap { s in
                guard let t = s.tenseEnum else { return nil }
                return WeakVerb(infinitive: s.verbInfinitive,
                                tense: t,
                                mastery: s.mastery,
                                attempts: s.attempts)
            }

        // Streak: consecutive days (ending today or yesterday) with a session.
        result.streak = computeStreak(sessions: langSessions)

        return result
    }

    /// Count of consecutive calendar days drilled, anchored at today/yesterday.
    static func computeStreak(sessions: [DrillSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })

        var streak = 0
        var cursor = cal.startOfDay(for: .now)

        // Allow the streak to anchor at yesterday if nothing today yet.
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
