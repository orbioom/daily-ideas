import Foundation

struct LevelProgress: Identifiable {
    let level: SkillLevel
    let mastered: Int
    let total: Int
    var id: String { level.rawValue }
    var fraction: Double { total == 0 ? 0 : Double(mastered) / Double(total) }
}

struct DayMinutes: Identifiable {
    let day: Date
    let minutes: Int
    var id: Date { day }
}

/// Pure logic over a dog's progress and sessions.
enum TrainerEngine {

    static func progress(for dog: Dog, skillID: String) -> SkillProgress? {
        dog.progresses.first { $0.skillID == skillID }
    }

    static func status(for dog: Dog, skill: Skill) -> SkillStatus {
        progress(for: dog, skillID: skill.id)?.status(stepCount: skill.steps.count) ?? .notStarted
    }

    static func levelProgress(for dog: Dog) -> [LevelProgress] {
        SkillLevel.allCases.map { level in
            let skills = Curriculum.skills(in: level)
            let mastered = skills.filter { status(for: dog, skill: $0) == .mastered }.count
            return LevelProgress(level: level, mastered: mastered, total: skills.count)
        }
    }

    static func masteredCount(for dog: Dog) -> Int {
        Curriculum.all.filter { status(for: dog, skill: $0) == .mastered }.count
    }

    /// Up to 3 suggested skills: stalest in-progress first, then the next
    /// untouched skill in curriculum order.
    static func recommended(for dog: Dog, limit: Int = 3) -> [Skill] {
        var result: [Skill] = []
        let inProgress = Curriculum.all
            .filter { skill in
                let s = status(for: dog, skill: skill)
                return s == .learning || s == .practicing
            }
            .sorted { a, b in
                let pa = progress(for: dog, skillID: a.id)?.lastPracticed ?? .distantPast
                let pb = progress(for: dog, skillID: b.id)?.lastPracticed ?? .distantPast
                return pa < pb
            }
        result.append(contentsOf: inProgress.prefix(limit))
        if result.count < limit {
            let fresh = Curriculum.all.filter { status(for: dog, skill: $0) == .notStarted }
            result.append(contentsOf: fresh.prefix(limit - result.count))
        }
        return result
    }

    /// Consecutive days with at least one session, ending today or yesterday.
    static func streak(for dog: Dog, calendar: