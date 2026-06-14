import Foundation

/// A badge the learner can earn. Pure value type; "unlocked" status is computed
/// from progress + session data rather than stored, so it always reflects truth.
struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let unlocked: Bool
    /// Progress toward unlocking, 0...1 (for partial display).
    let progress: Double

    /// Build the full achievement set from aggregate stats.
    static func evaluate(totalCorrect: Int,
                         masteredCount: Int,
                         continentMastery: [Continent: Double],
                         bestStreak: Int,
                         sessionsPlayed: Int,
                         dailyDone: Bool) -> [Achievement] {

        func ratioBadge(id: String, title: String, detail: String, image: String,
                        value: Int, goal: Int) -> Achievement {
            let p = goal > 0 ? min(1.0, Double(value) / Double(goal)) : 0
            return Achievement(id: id, title: title, detail: detail,
                               systemImage: image, unlocked: value >= goal, progress: p)
        }

        var list: [Achievement] = [
            ratioBadge(id: "first-quiz", title: "First Steps",
                       detail: "Finish your first quiz.", image: "figure.walk",
                       value: sessionsPlayed, goal: 1),
            ratioBadge(id: "correct-100", title: "Centurion",
                       detail: "Answer 100 questions correctly.", image: "checkmark.seal.fill",
                       value: totalCorrect, goal: 100),
            ratioBadge(id: "correct-500", title: "Cartographer",
                       detail: "Answer 500 questions correctly.", image: "map.fill",
                       value: totalCorrect, goal: 500),
            ratioBadge(id: "mastered-25", title: "Globe Trotter",
                       detail: "Master 25 countries.", image: "globe",
                       value: masteredCount, goal: 25),
            ratioBadge(id: "streak-7", title: "Week on the Map",
                       detail: "Reach a 7-day streak.", image: "flame.fill",
                       value: bestStreak, goal: 7),
            Achievement(id: "daily", title: "Daily Explorer",
                        detail: "Complete today's daily challenge.",
                        systemImage: "calendar", unlocked: dailyDone,
                        progress: dailyDone ? 1 : 0)
        ]

        // Per-continent expert badges (>= 80% average mastery).
        for c in Continent.displayOrder {
            let m = continentMastery[c] ?? 0
            list.append(Achievement(id: "expert-\(c.rawValue)",
                                    title: "\(c.title) Expert",
                                    detail: "Average 80% mastery across \(c.title).",
                                    systemImage: c.systemImage,
                                    unlocked: m >= 0.8,
                                    progress: min(1.0, m / 0.8)))
        }
        return list
    }
}
