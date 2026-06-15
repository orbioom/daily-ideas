import Foundation
import SwiftData

// MARK: - Companion

@Model
final class Companion {
    var name: String
    var level: Int
    var xp: Int
    var energy: Int            // 0...100
    var pebbles: Int           // spendable currency
    var bornAt: Date
    var lastTendedAt: Date     // last time a goal was completed; drives energy decay

    /// Owned cosmetic identifiers (accessories / scenes), stored as a string array.
    var ownedCosmetics: [String]
    /// Currently equipped accessory identifier, if any.
    var equippedAccessory: String?

    init(
        name: String,
        level: Int = 1,
        xp: Int = 0,
        energy: Int = 60,
        pebbles: Int = 20,
        bornAt: Date = Date(),
        lastTendedAt: Date = Date(),
        ownedCosmetics: [String] = [],
        equippedAccessory: String? = nil
    ) {
        self.name = name
        self.level = level
        self.xp = xp
        self.energy = energy
        self.pebbles = pebbles
        self.bornAt = bornAt
        self.lastTendedAt = lastTendedAt
        self.ownedCosmetics = ownedCosmetics
        self.equippedAccessory = equippedAccessory
    }
}

// MARK: - SelfCareGoal

@Model
final class SelfCareGoal {
    var title: String
    var categoryRaw: String
    var scheduleKindRaw: String
    var weekdayMask: Int       // used when scheduleKind == specificDays
    var timesPerWeek: Int      // used when scheduleKind == timesPerWeek
    var pebbleReward: Int
    var energyReward: Int
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \GoalCompletion.goal)
    var completions: [GoalCompletion]

    init(
        title: String,
        category: GoalCategory,
        schedule: GoalSchedule,
        pebbleReward: Int = 5,
        energyReward: Int = 8,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.title = title
        self.categoryRaw = category.rawValue
        switch schedule {
        case .everyDay:
            self.scheduleKindRaw = ScheduleKind.everyDay.rawValue
            self.weekdayMask = 0
            self.timesPerWeek = 0
        case .specificDays(let mask):
            self.scheduleKindRaw = ScheduleKind.specificDays.rawValue
            self.weekdayMask = mask
            self.timesPerWeek = 0
        case .timesPerWeek(let n):
            self.scheduleKindRaw = ScheduleKind.timesPerWeek.rawValue
            self.weekdayMask = 0
            self.timesPerWeek = n
        }
        self.pebbleReward = pebbleReward
        self.energyReward = energyReward
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.completions = []
    }

    var category: GoalCategory {
        GoalCategory(rawValue: categoryRaw) ?? .mind
    }

    var schedule: GoalSchedule {
        switch ScheduleKind(rawValue: scheduleKindRaw) {
        case .everyDay, .none:
            return .everyDay
        case .specificDays:
            return .specificDays(mask: weekdayMask)
        case .timesPerWeek:
            return .timesPerWeek(max(1, timesPerWeek))
        }
    }

    /// True if this goal is due to be offered on the given day.
    func isDue(on date: Date = Date()) -> Bool {
        !isArchived && schedule.isDue(on: date)
    }

    /// True if completed already on the given day.
    func isCompleted(on date: Date = Date()) -> Bool {
        completions.contains { DateUtils.isSameDay($0.date, date) }
    }
}

// MARK: - GoalCompletion

@Model
final class GoalCompletion {
    var date: Date             // day-stamped (start of day)
    var pebblesAwarded: Int
    var energyAwarded: Int
    var goal: SelfCareGoal?

    init(date: Date, pebblesAwarded: Int, energyAwarded: Int, goal: SelfCareGoal? = nil) {
        self.date = DateUtils.startOfDay(date)
        self.pebblesAwarded = pebblesAwarded
        self.energyAwarded = energyAwarded
        self.goal = goal
    }
}

// MARK: - CheckIn (daily reflection)

@Model
final class CheckIn {
    var date: Date             // day-stamped
    var mood: Int              // 1...5
    var note: String
    var gratitude: String?

    init(date: Date = Date(), mood: Int, note: String = "", gratitude: String? = nil) {
        self.date = DateUtils.startOfDay(date)
        self.mood = min(5, max(1, mood))
        self.note = note
        self.gratitude = gratitude
    }
}

// MARK: - Journey

@Model
final class Journey {
    var title: String
    var detail: String
    var requiredCompletions: Int
    var energyCost: Int
    var rewardName: String
    var rewardKindRaw: String
    var rewardScene: String         // scene identifier for the postcard art
    var rewardPebbles: Int          // payout when rewardKind == pebbles
    var progressCount: Int
    var startedAt: Date?
    var completedAt: Date?
    var isActive: Bool
    var isPro: Bool
    var sortOrder: Int

    init(
        title: String,
        detail: String,
        requiredCompletions: Int,
        energyCost: Int,
        rewardName: String,
        rewardKind: RewardKind,
        rewardScene: String,
        rewardPebbles: Int = 0,
        isPro: Bool = false,
        sortOrder: Int = 0
    ) {
        self.title = title
        self.detail = detail
        self.requiredCompletions = max(1, requiredCompletions)
        self.energyCost = max(0, energyCost)
        self.rewardName = rewardName
        self.rewardKindRaw = rewardKind.rawValue
        self.rewardScene = rewardScene
        self.rewardPebbles = rewardPebbles
        self.progressCount = 0
        self.startedAt = nil
        self.completedAt = nil
        self.isActive = false
        self.isPro = isPro
        self.sortOrder = sortOrder
    }

    var rewardKind: RewardKind {
        RewardKind(rawValue: rewardKindRaw) ?? .postcard
    }

    var isCompleted: Bool { completedAt != nil }

    var fractionComplete: Double {
        guard requiredCompletions > 0 else { return 0 }
        return min(1, Double(progressCount) / Double(requiredCompletions))
    }
}

// MARK: - Postcard / Collectible

@Model
final class Postcard {
    var title: String
    var scene: String          // scene identifier → drawn art
    var caption: String
    var earnedAt: Date

    init(title: String, scene: String, caption: String, earnedAt: Date = Date()) {
        self.title = title
        self.scene = scene
        self.caption = caption
        self.earnedAt = earnedAt
    }
}
