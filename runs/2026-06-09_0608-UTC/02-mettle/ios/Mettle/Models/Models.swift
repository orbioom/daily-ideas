import Foundation
import SwiftData

/// A fixed-length challenge program (e.g. "75 Hard"). A day only "passes" when
/// every required task is satisfied. In hard mode, missing a day resets the run
/// to Day 1; in soft mode the streak breaks but the run continues.
@Model
final class Challenge {
    var name: String
    var summary: String
    var durationDays: Int
    var isBuiltIn: Bool
    var isActive: Bool
    var startDate: Date?
    var hardMode: Bool
    var createdAt: Date
    var sortIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \ChallengeTask.challenge)
    var tasks: [ChallengeTask] = []

    @Relationship(deleteRule: .cascade, inverse: \DayLog.challenge)
    var dayLogs: [DayLog] = []

    init(name: String,
         summary: String = "",
         durationDays: Int,
         isBuiltIn: Bool = false,
         isActive: Bool = false,
         startDate: Date? = nil,
         hardMode: Bool = false,
         sortIndex: Int = 0) {
        self.name = name
        self.summary = summary
        self.durationDays = min(max(durationDays, 1), 365)
        self.isBuiltIn = isBuiltIn
        self.isActive = isActive
        self.startDate = startDate
        self.hardMode = hardMode
        self.createdAt = .now
        self.sortIndex = sortIndex
    }

    /// Tasks sorted by their authored order.
    var orderedTasks: [ChallengeTask] {
        tasks.sorted { $0.order < $1.order }
    }

    var modeLabel: String { hardMode ? "Hard" : "Soft" }
}

/// A single daily rule within a challenge. `targetValue > 0` makes the task
/// measured (e.g. 128 oz water); otherwise it is a simple checkbox.
@Model
final class ChallengeTask {
    var title: String
    var detail: String
    var iconName: String
    var targetValue: Double
    var unit: String
    var order: Int
    var challenge: Challenge?

    init(title: String,
         detail: String = "",
         iconName: String = "checkmark.circle",
         targetValue: Double = 0,
         unit: String = "",
         order: Int = 0) {
        self.title = title
        self.detail = detail
        self.iconName = iconName.isEmpty ? "checkmark.circle" : iconName
        self.targetValue = max(0, targetValue)
        self.unit = unit
        self.order = order
    }

    var isMeasured: Bool { targetValue > 0 }
}

/// A record for one calendar day of an active run. `date` is normalized to the
/// start of the day. `dayIndex` is 1-based.
@Model
final class DayLog {
    var date: Date
    var dayIndex: Int
    var challenge: Challenge?

    @Relationship(deleteRule: .cascade, inverse: \TaskTick.dayLog)
    var ticks: [TaskTick] = []

    init(date: Date, dayIndex: Int) {
        self.date = date
        self.dayIndex = max(1, dayIndex)
    }
}

/// A snapshot of a single task's completion within a `DayLog`.
@Model
final class TaskTick {
    var taskTitle: String
    var done: Bool
    var value: Double
    var target: Double
    var dayLog: DayLog?

    init(taskTitle: String,
         done: Bool = false,
         value: Double = 0,
         target: Double = 0) {
        self.taskTitle = taskTitle
        self.done = done
        self.value = max(0, value)
        self.target = max(0, target)
    }

    /// A tick is satisfied when checked, or when its measured value meets target.
    var satisfied: Bool { done || (target > 0 && value >= target) }
}
