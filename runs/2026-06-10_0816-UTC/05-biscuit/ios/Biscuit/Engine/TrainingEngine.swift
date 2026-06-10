import Foundation

struct DayCount: Identifiable {
    let day: Date
    let count: Int
    var id: Date { day }
}

struct LevelProgress: Identifiable {
    let level: SkillLevel
    let mastered: Int
    let total: Int
    var id: String { level.rawValue }
    var fraction: Double { total == 0 ? 0 : Double(mastered) / Double(total) }
}

struct DogStats {
    let masteredCount: Int
    let inProgressCount: Int
    let totalSkills: Int
    let sessionCount: Int
    let totalMinutes: Int
    let streak: Int
    let sessionsPerDay: [DayCount]      // last 14 days
    let levelProgress: [LevelProgress]
    let greatRate: Double               // share of sessions rated "great"
}

/// Pure aggregation over one dog's progress and session log.
enum TrainingEngine {

    static func progress(for dog: Dog, skillID: String) -> SkillProgress? {
        dog.progresses.first { $0.skillID == skillID }
    }

    static func status(for dog: Dog, skill: Skill) -> SkillStatus {
        progress(for: dog, skillID: skill.id)?.status(stepCount: skill.steps.count) ?? .notStarted
    }

    /// The next sensible skill to work on: the first non-mastered skill in
    /// curriculum order whose prerequisites (everything earlier) are at least
    /// started — falls back to the first unmastered skill.
    static func suggestedSkill(for dog: Dog) -> Skill? {
        let unmastered = Curriculum.all.first { skill in
            status(for: dog, skill: skill) != .mastered
        }
        return unmastered
    }

    static func stats(for dog: Dog, calendar: Calendar = .current, now: Date = .now) -> DogStats {
        let mastered = dog.progresses.filter { $0.masteredAt != nil }.count
        let inProgress = dog.progresses.filter { p in
            guard let skill = Curriculum.skill(id: p.skillID) else { return false }
            let s = p.status(stepCount: skill.steps.count)
            return s == .learning || s == .practicing
        }.count

        let sessions = dog.sessions
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let great = sessions.filter { $0.rating == 3 }.count

        // Sessions per day, last 14 days.
        var perDay: [DayCount] = []
        let today = calendar.startOfDay(for: now)
        for back in stride(from: 13, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -back, to: today),
                  let next = calendar.date(byAdding: .day, value: 1, to: day) else { continue }
            let n = sessions.filter { $0.date >= day && $0.date < next }.count
            perDay.append(DayCount(day: day, count: n))
        }

        // Practice-day streak.
        let trainingDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = today
        if !trainingDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while trainingDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        let levels = SkillLevel.allCases.map { level -> LevelProgress in
            let skills = Curriculum.skills(in: level)
            let done = skills.filter { status(for: dog, skill: $0) == .mastered }.count
            return LevelProgress(level: level, mastered: done, total: skills.count)
        }

        return DogStats(
            masteredCount: mastered,
            inProgressCount: inProgress,
            totalSkills: Curriculum.all.count,
            sessionCount: sessions.count,
            totalMinutes: totalMinutes,
            streak: streak,
            sessionsPerDay: perDay,
            levelProgress: levels,
            greatRate: sessions.isEmpty ? 0 : Double(great) / Double(sessions.count)
        )
    }
}

enum DurationFormat {
    static func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func friendly(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}
