import Foundation
import SwiftData

/// Seeds realistic first-run data so Insights, charts, streaks and the collection
/// look alive immediately. Idempotent: only seeds when the store is empty.
@MainActor
enum SeedData {

    /// Catalog of journeys offered in the app. Stable identifiers via title+sortOrder.
    static func journeyCatalog() -> [Journey] {
        [
            Journey(title: "Morning Meadow", detail: "A gentle three-day stroll through dew-lit grass.",
                    requiredCompletions: 3, energyCost: 15,
                    rewardName: "Meadow at Dawn", rewardKind: .postcard, rewardScene: "meadow",
                    sortOrder: 0),
            Journey(title: "Quiet Harbour", detail: "Five small acts of care carry Wren to a calm shore.",
                    requiredCompletions: 5, energyCost: 20,
                    rewardName: "Harbour Lights", rewardKind: .postcard, rewardScene: "harbour",
                    sortOrder: 1),
            Journey(title: "The Little Cap", detail: "Earn a cosy knitted cap for your Wren.",
                    requiredCompletions: 4, energyCost: 18,
                    rewardName: "Knitted Cap", rewardKind: .cosmetic, rewardScene: "cap",
                    sortOrder: 2),
            Journey(title: "Pebble Cache", detail: "A week of steady care reveals a hidden cache of pebbles.",
                    requiredCompletions: 7, energyCost: 25,
                    rewardName: "Hidden Pebbles", rewardKind: .pebbles, rewardScene: "cache", rewardPebbles: 60,
                    sortOrder: 3),
            Journey(title: "Highland Trek", detail: "A longer, Pro-only climb to a windswept ridge.",
                    requiredCompletions: 10, energyCost: 35,
                    rewardName: "Ridge Sunset", rewardKind: .postcard, rewardScene: "highland",
                    isPro: true, sortOrder: 4),
            Journey(title: "Starlit Scarf", detail: "A Pro cosmetic — a scarf woven from quiet evenings.",
                    requiredCompletions: 8, energyCost: 30,
                    rewardName: "Starlit Scarf", rewardKind: .cosmetic, rewardScene: "scarf",
                    isPro: true, sortOrder: 5),
        ]
    }

    static func starterGoals() -> [SelfCareGoal] {
        [
            SelfCareGoal(title: "Take a short walk", category: .move, schedule: .everyDay, pebbleReward: 6, energyReward: 10),
            SelfCareGoal(title: "Drink a glass of water", category: .nourish, schedule: .everyDay, pebbleReward: 4, energyReward: 6),
            SelfCareGoal(title: "Five slow breaths", category: .mind, schedule: .everyDay, pebbleReward: 5, energyReward: 8),
            SelfCareGoal(title: "Tidy one small space", category: .tidy, schedule: .specificDays(mask: weekdayMask([2, 4, 6])), pebbleReward: 6, energyReward: 8),
            SelfCareGoal(title: "Message someone you love", category: .connect, schedule: .timesPerWeek(3), pebbleReward: 7, energyReward: 9),
            SelfCareGoal(title: "Wind down without a screen", category: .rest, schedule: .everyDay, pebbleReward: 6, energyReward: 10),
        ]
    }

    /// Bitmask from weekday numbers (1=Sun ... 7=Sat).
    static func weekdayMask(_ weekdays: [Int]) -> Int {
        weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
    }

    static func seedIfNeeded(context: ModelContext, companionName: String? = nil) {
        // Only seed if there is no companion yet.
        let companionCount = (try? context.fetchCount(FetchDescriptor<Companion>())) ?? 0
        guard companionCount == 0 else { return }

        let trimmedName = (companionName ?? "").trimmingCharacters(in: .whitespaces)
        let name = trimmedName.isEmpty ? "Wren" : trimmedName
        let companion = Companion(name: name, level: 1, xp: 0, energy: 60, pebbles: 40,
                                  bornAt: DateUtils.adding(days: -45), lastTendedAt: Date())
        context.insert(companion)

        let goals = starterGoals()
        goals.forEach { context.insert($0) }

        SeedData.journeyCatalog().forEach { context.insert($0) }

        // Backdated completions + check-ins for ~45 days, with a realistic adherence pattern.
        var totalXP = 0
        var rng = SeededGenerator(seed: 20260615)
        let today = DateUtils.startOfDay()
        for offset in stride(from: 45, through: 1, by: -1) {
            let day = DateUtils.adding(days: -offset, to: today)
            // ~78% of days have activity; recent days slightly more consistent.
            let activeChance = offset < 14 ? 0.84 : 0.74
            guard Double(rng.nextUnit()) < activeChance else { continue }

            // 1–4 goals completed that day.
            let count = 1 + Int(rng.next() % 4)
            let shuffled = goals.shuffled(using: &rng)
            for goal in shuffled.prefix(count) where goal.isDue(on: day) {
                let award = CareEngine.award(for: goal)
                let completion = GoalCompletion(date: day, pebblesAwarded: award.pebbles, energyAwarded: award.energy, goal: goal)
                context.insert(completion)
                companion.pebbles += award.pebbles
                totalXP += award.xp
            }

            // Most active days also get a check-in.
            if Double(rng.nextUnit()) < 0.7 {
                let mood = 3 + Int(rng.next() % 3) - Int(rng.next() % 2) // roughly 2...5 centered ~3.5
                let clampedMood = min(5, max(1, mood))
                let checkIn = CheckIn(
                    date: day,
                    mood: clampedMood,
                    note: SeedData.sampleNotes[Int(rng.next() % UInt64(sampleNotes.count))],
                    gratitude: Double(rng.nextUnit()) < 0.5 ? sampleGratitude[Int(rng.next() % UInt64(sampleGratitude.count))] : nil
                )
                context.insert(checkIn)
            }
        }

        companion.xp = totalXP
        let lvl = CareEngine.levelProgress(totalXP: totalXP)
        companion.level = lvl.level
        companion.energy = 64
        companion.lastTendedAt = DateUtils.adding(days: -1, to: today)

        // A previously completed journey so the collection isn't empty.
        if let firstJourney = SeedData.journeyCatalog().first {
            let earned = Postcard(title: firstJourney.rewardName, scene: firstJourney.rewardScene,
                                  caption: firstJourney.detail, earnedAt: DateUtils.adding(days: -20))
            context.insert(earned)
        }

        try? context.save()
    }

    static let sampleNotes = [
        "A slow morning. Felt steady.",
        "Busy, but I made a little room for myself.",
        "Tired today — kept things small.",
        "Good walk, clearer head afterwards.",
        "Reached out to a friend. Glad I did.",
        "Quiet evening, early to bed.",
        "Felt scattered but I tried anyway.",
    ]

    static let sampleGratitude = [
        "Warm tea by the window.",
        "A kind text from someone.",
        "The light this afternoon.",
        "Getting outside, even briefly.",
        "A moment of real quiet.",
    ]
}

/// Tiny deterministic RNG so seeded data is stable across runs.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed != 0 ? seed : 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    /// 0.0..<1.0
    mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
