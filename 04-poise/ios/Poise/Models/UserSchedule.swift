import SwiftData
import Foundation

@Model
final class UserSchedule {
    var intervalMinutes: Int
    var breakDurationSeconds: Int
    var startHour: Int
    var endHour: Int
    var enabledDaysArray: [Bool]
    var exerciseCategoriesArray: [String]
    var remindersEnabled: Bool
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var dailyBreakGoal: Int
    var totalBreaksTaken: Int
    var currentStreakDays: Int
    var lastBreakDate: Date?
    var nextBreakDate: Date?
    var isPro: Bool

    init() {
        intervalMinutes = 30
        breakDurationSeconds = 120
        startHour = 9
        endHour = 17
        enabledDaysArray = [true, true, true, true, true, false, false]
        exerciseCategoriesArray = ["neck", "shoulders", "eyes", "wrists", "back"]
        remindersEnabled = false
        hapticsEnabled = true
        soundEnabled = true
        dailyBreakGoal = 4
        totalBreaksTaken = 0
        currentStreakDays = 0
        lastBreakDate = nil
        nextBreakDate = nil
        isPro = false
    }
}
