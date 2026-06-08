import Foundation
import SwiftData

enum ScheduleType: String, Codable, CaseIterable {
    case everyDay       = "everyDay"
    case specificDays   = "specificDays"
    case timesPerWeek   = "timesPerWeek"

    var displayName: String {
        switch self {
        case .everyDay:      return "Every Day"
        case .specificDays:  return "Specific Days"
        case .timesPerWeek:  return "Times per Week"
        }
    }
}

enum Polarity: String, Codable, CaseIterable {
    case build = "build"
    case quit  = "quit"

    var displayName: String {
        switch self {
        case .build: return "Build"
        case .quit:  return "Quit"
        }
    }
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: UInt32
    var scheduleType: ScheduleType
    var weekdayMask: Int        // bitmask: bit 1 = Mon … bit 7 = Sun (Calendar weekday 2–1)
    var timesPerWeekTarget: Int
    var dailyTarget: Int
    var unit: String
    var polarity: Polarity
    var createdAt: Date
    var order: Int
    var archived: Bool

    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: UInt32,
        scheduleType: ScheduleType = .everyDay,
        weekdayMask: Int = 0b1111111,
        timesPerWeekTarget: Int = 3,
        dailyTarget: Int = 1,
        unit: String = "",
        polarity: Polarity = .build,
        createdAt: Date = .now,
        order: Int = 0,
        archived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.scheduleType = scheduleType
        self.weekdayMask = weekdayMask
        self.timesPerWeekTarget = timesPerWeekTarget
        self.dailyTarget = dailyTarget
        self.unit = unit
        self.polarity = polarity
        self.createdAt = createdAt
        self.order = order
        self.archived = archived
    }
}

@Model
final class HabitEntry {
    var id: UUID
    var day: Date       // always startOfDay
    var count: Int
    var habit: Habit?

    init(id: UUID = UUID(), day: Date, count: Int, habit: Habit? = nil) {
        self.id = id
        self.day = day
        self.count = count
        self.habit = habit
    }
}
