import Foundation
import SwiftData

@Model
final class Dog {
    var uuid: UUID
    var name: String
    var breed: String
    var birthDate: Date?
    var emoji: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SkillProgress.dog)
    var progresses: [SkillProgress] = []
    @Relationship(deleteRule: .cascade, inverse: \TrainingSession.dog)
    var sessions: [TrainingSession] = []

    init(name: String, breed: String = "", birthDate: Date? = nil,
         emoji: String = "🐶", createdAt: Date = .now) {
        self.uuid = UUID()
        self.name = name
        self.breed = breed
        self.birthDate = birthDate
        self.emoji = emoji
        self.createdAt = createdAt
    }

    var ageDescription: String? {
        guard let birthDate else { return nil }
        let months = Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0
        if months < 12 { return "\(max(months, 0)) mo" }
        return "\(months / 12) yr"
    }
}

enum SkillStatus: String {
    case notStarted, learning, practicing, mastered

    var label: String {
        switch self {
        case .notStarted: return "Not started"
        case .learning: return "Learning"
        case .practicing: return "Practicing"
        case .mastered: return "Mastered"
        }
    }
}

/// One dog's progress through one curriculum skill. Steps complete in order;
/// when all are done the skill is "practicing" until you mark it mastered.
@Model
final class SkillProgress {
    var skillID: String
    var completedSteps: Int
    var masteredAt: Date?
    var startedAt: Date?
    var lastPracticed: Date?
    var dog: Dog?

    init(skillID: String) {
        self.skillID = skillID
        self.completedSteps = 0
        self.masteredAt = nil
        self.startedAt = nil
        self.lastPracticed = nil
    }

    func status(stepCount: Int) -> SkillStatus {
        if masteredAt != nil { return .mastered }
        if completedSteps == 0 { return .notStarted }
        if completedSteps >= stepCount { return .practicing }
        return .learning
    }
}

@Model
final class TrainingSession {
    var date: Date
    var skillID: String
    var durationSeconds: Int
    var rating: Int          // 1 tough · 2 okay · 3 great
    var clicks: Int
    var note: String
    var dog: Dog?

    init(date: Date = .now, skillID: String, durationSeconds: Int,
         rating: Int, clicks: Int = 0, note: String = "") {
        self.date = date
        self.skillID = skillID
        self.durationSeconds = durationSeconds
        self.rating = rating
        self.clicks = clicks
        self.note = note
    }

    var ratingEmoji: String {
        switch rating {
        case 3: return "🎉"
        case 2: return "🙂"
        default: return "😮‍💨"
        }
    }
}
