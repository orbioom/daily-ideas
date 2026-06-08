import Foundation
import SwiftData

enum SampleData {

    static func seed(into context: ModelContext, calendar: Calendar) {
        let definitions: [(name: String, symbol: String, hex: UInt32, schedule: ScheduleType, mask: Int, tpw: Int, daily: Int, unit: String, polarity: Polarity, daysAgo: Int)] = [
            ("Morning Run",       "figure.run",          0x4FB98C, .everyDay,      0,         3, 1,  "",       .build, 75),
            ("Read 30 mins",      "book.fill",            0x4E6BA8, .everyDay,      0,         3, 1,  "",       .build, 60),
            ("Drink Water",       "drop.fill",            0x3E9E78, .everyDay,      0,         3, 8,  "glasses",.build, 65),
            ("No Alcohol",        "wineglass",            0xC0553E, .everyDay,      0,         3, 1,  "",       .quit,  70),
            ("Meditate",          "brain.head.profile",   0x8B5CF6, .specificDays,  0b0111110, 3, 1,  "",       .build, 55),
            ("Strength Train",    "dumbbell.fill",        0xE0B86A, .specificDays,  0b0101010, 3, 1,  "",       .build, 60),
            ("Journaling",        "pencil.and.scribble",  0xC08A3E, .timesPerWeek,  0,         4, 1,  "",       .build, 50),
        ]

        let today = calendar.startOfDay(for: .now)

        var orderIdx = 0
        for def in definitions {
            let habit = Habit(
                name: def.name,
                symbol: def.symbol,
                colorHex: def.hex,
                scheduleType: def.schedule,
                weekdayMask: def.mask == 0 ? 0b1111111 : def.mask,
                timesPerWeekTarget: def.tpw,
                dailyTarget: def.daily,
                unit: def.unit,
                polarity: def.polarity,
                createdAt: calendar.date(byAdding: .day, value: -(def.daysAgo), to: today) ?? today,
                order: orderIdx
            )
            context.insert(habit)
            orderIdx += 1

            generateEntries(for: habit, today: today, calendar: calendar, context: context)
        }
    }

    // MARK: - Entry generation

    private static func generateEntries(
        for habit: Habit,
        today: Date,
        calendar: Calendar,
        context: ModelContext
    ) {
        let createdDay = calendar.startOfDay(for: habit.createdAt)
        var cursor = createdDay

        // Random seed per habit for deterministic variety
        var rng = SeededRNG(seed: habit.name.hashValue)

        while cursor <= today {
            let shouldLog = shouldCreateEntry(for: habit, on: cursor, today: today,
                                               calendar: calendar, rng: &rng)
            if shouldLog {
                let entryCount = entryCount(for: habit, rng: &rng)
                let entry = HabitEntry(day: cursor, count: entryCount, habit: habit)
                context.insert(entry)
                habit.entries.append(entry)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
    }

    private static func shouldCreateEntry(
        for habit: Habit,
        on day: Date,
        today: Date,
        calendar: Calendar,
        rng: inout SeededRNG
    ) -> Bool {
        // Don't add entries for today (user creates those themselves)
        if calendar.startOfDay(for: day) == calendar.startOfDay(for: today) { return false }

        guard StreakEngine.isScheduled(habit, on: day, calendar: calendar) else { return false }

        let daysAgo = calendar.dateComponents([.day], from: day, to: today).day ?? 0
        // More consistent completion in recent weeks, taper off further back
        let baseRate: Double
        switch habit.polarity {
        case .build:
            baseRate = daysAgo < 14 ? 0.85 : (daysAgo < 30 ? 0.72 : 0.60)
        case .quit:
            baseRate = daysAgo < 14 ? 0.90 : (daysAgo < 30 ? 0.80 : 0.68)
        }

        return rng.nextDouble() < baseRate
    }

    private static func entryCount(for habit: Habit, rng: inout SeededRNG) -> Int {
        guard habit.dailyTarget > 1 else { return 1 }
        // Randomly log between target and target+2
        let bonus = Int(rng.nextDouble() * 3)
        return habit.dailyTarget + bonus
    }
}

// MARK: - Minimal seeded RNG (Xorshift64)

private struct SeededRNG {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed &* 6364136223846793005 &+ 1442695040888963407))
        if state == 0 { state = 1 }
    }

    mutating func nextUInt64() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(nextUInt64() >> 11) / Double(1 << 53)
    }
}
