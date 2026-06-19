import Foundation
import SwiftData

@Model
final class UserSettings {
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var dailyGoalMinutes: Int
    var streakCount: Int
    var lastPracticeDate: Date?
    var completedLessonsJSON: String // JSON-encoded [String]
    var hasCompletedOnboarding: Bool
    var showNoteLabels: Bool
    var hasPro: Bool

    init(
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = true,
        dailyGoalMinutes: Int = 10,
        streakCount: Int = 0,
        lastPracticeDate: Date? = nil,
        completedLessonsJSON: String = "[]",
        hasCompletedOnboarding: Bool = false,
        showNoteLabels: Bool = true,
        hasPro: Bool = false
    ) {
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.dailyGoalMinutes = dailyGoalMinutes
        self.streakCount = streakCount
        self.lastPracticeDate = lastPracticeDate
        self.completedLessonsJSON = completedLessonsJSON
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.showNoteLabels = showNoteLabels
        self.hasPro = hasPro
    }

    var completedLessons: [String] {
        get {
            guard let data = completedLessonsJSON.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return arr
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let str = String(data: data, encoding: .utf8)
            else { return }
            completedLessonsJSON = str
        }
    }

    func markLessonCompleted(_ lessonId: String) {
        var current = completedLessons
        if !current.contains(lessonId) {
            current.append(lessonId)
            completedLessons = current
        }
    }

    func isLessonCompleted(_ lessonId: String) -> Bool {
        completedLessons.contains(lessonId)
    }
}
