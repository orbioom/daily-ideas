import Foundation

/// A milestone the learner can unlock. Pure value type; unlock state is derived
/// from progress + sessions, so there is nothing extra to persist.
struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let isUnlocked: Bool
    /// 0...1 progress toward unlocking (for the partial ring).
    let fraction: Double
}

enum AchievementEngine {

    /// Builds the full achievement list against current stats.
    static func all(progress: [WordProgress], sessions: [StudySession], now: Date = Date()) -> [Achievement] {
        let learned = LexemeEngine.learnedCount(progress)
        let streak = LexemeEngine.streak(sessions, now: now)
        let sessionCount = sessions.count
        let totalAnswered = sessions.reduce(0) { $0 + $1.total }
        let accuracy = LexemeEngine.overallAccuracy(sessions)
        let mastered = progress.filter { LexemeEngine.isMastered(level: $0.level) }.count

        func milestone(_ id: String, _ title: String, _ detail: String, _ image: String,
                       value: Int, goal: Int) -> Achievement {
            let frac = goal > 0 ? min(Double(value) / Double(goal), 1) : 0
            return Achievement(id: id, title: title, detail: detail, systemImage: image,
                               isUnlocked: value >= goal, fraction: frac)
        }

        return [
            milestone("first_word", "First Light", "Learn your first word.", "sparkles",
                      value: learned, goal: 1),
            milestone("ten_words", "Word Collector", "Learn 10 words.", "books.vertical",
                      value: learned, goal: 10),
            milestone("fifty_words", "Lexicographer", "Learn 50 words.", "text.book.closed",
                      value: learned, goal: 50),
            milestone("streak3", "Kindling", "Reach a 3-day streak.", "flame",
                      value: streak, goal: 3),
            milestone("streak7", "Steady Flame", "Reach a 7-day streak.", "flame.fill",
                      value: streak, goal: 7),
            milestone("sessions5", "Regular", "Finish 5 study sessions.", "checkmark.seal",
                      value: sessionCount, goal: 5),
            milestone("answered100", "Centurion", "Answer 100 questions.", "100.circle",
                      value: totalAnswered, goal: 100),
            milestone("mastered5", "Master Scholar", "Master 5 words to the top level.", "crown",
                      value: mastered, goal: 5),
            Achievement(id: "sharpshooter", title: "Sharpshooter",
                        detail: "Reach 90% lifetime accuracy (50+ answered).",
                        systemImage: "scope",
                        isUnlocked: totalAnswered >= 50 && accuracy >= 0.9,
                        fraction: totalAnswered >= 50 ? min(accuracy / 0.9, 1) : Double(totalAnswered) / 50.0),
        ]
    }
}
