import SwiftData
import Foundation

@Model final class BreakRecord {
    var date: Date
    var exerciseName: String
    var durationSeconds: Int
    var wasCompleted: Bool
    var wasSkipped: Bool
    var breakType: String

    init(exerciseName: String, duration: Int, breakType: String = "scheduled") {
        self.date = Date()
        self.exerciseName = exerciseName
        self.durationSeconds = duration
        self.wasCompleted = false
        self.wasSkipped = false
        self.breakType = breakType
    }
}

@Model final class UserSchedule {
    var intervalMinutes: Int
    var breakDurationSeconds: Int
    var startHour: Int
    var endHour: Int
    var enabledDays: String
    var exerciseCategories: String
    var remindersEnabled: Bool
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var lastBreakDate: Date?
    var nextBreakDate: Date?
    var currentStreakDays: Int
    var totalBreaksTaken: Int
    var isPro: Bool
    var dailyBreakGoal: Int

    init() {
        self.intervalMinutes = 30
        self.breakDurationSeconds = 120
        self.startHour = 9
        self.endHour = 18
        self.enabledDays = "[true,true,true,true,true,false,false]"
        self.exerciseCategories = "[\"neck\",\"shoulders\",\"eyes\",\"wrists\"]"
        self.remindersEnabled = true
        self.hapticsEnabled = true
        self.soundEnabled = false
        self.currentStreakDays = 0
        self.totalBreaksTaken = 0
        self.isPro = false
        self.dailyBreakGoal = 8
    }

    var enabledDaysArray: [Bool] {
        get {
            (try? JSONDecoder().decode([Bool].self, from: Data(enabledDays.utf8))) ?? Array(repeating: true, count: 7)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                enabledDays = str
            }
        }
    }

    var exerciseCategoriesArray: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(exerciseCategories.utf8))) ?? ["neck", "shoulders", "eyes", "wrists"]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                exerciseCategories = str
            }
        }
    }
}
