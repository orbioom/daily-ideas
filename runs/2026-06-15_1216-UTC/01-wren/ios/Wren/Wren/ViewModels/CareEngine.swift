import Foundation

/// Pure, testable self-care engine. No SwiftData / SwiftUI imports — it operates on
/// values and model objects but performs no persistence itself.
enum CareEngine {

    // MARK: - Energy decay

    /// Energy decays by a small amount per neglected day. Computed lazily from the
    /// number of days since the companion was last tended. Never below 0, never above 100.
    static let decayPerDay = 6

    static func decayedEnergy(current: Int, lastTendedAt: Date, now: Date = Date()) -> Int {
        let days = DateUtils.daysBetween(lastTendedAt, now)
        // No decay on the same day it was tended.
        let lost = days * decayPerDay
        return clampEnergy(current - lost)
    }

    static func clampEnergy(_ value: Int) -> Int {
        min(100, max(0, value))
    }

    // MARK: - Level / XP

    /// Level n requires n * 100 cumulative XP to reach level n+1.
    /// Returns (level, xpIntoLevel, xpForNextLevel).
    static func levelProgress(totalXP: Int) -> (level: Int, xpInto: Int, xpNeeded: Int) {
        let xp = max(0, totalXP)
        var level = 1
        var remaining = xp
        // Threshold to advance FROM level L is L * 100.
        while remaining >= level * 100 {
            remaining -= level * 100
            level += 1
            if level > 999 { break } // guard against pathological overflow
        }
        return (level, remaining, level * 100)
    }

    static func levelFraction(totalXP: Int) -> Double {
        let p = levelProgress(totalXP: totalXP)
        guard p.xpNeeded > 0 else { return 0 }
        return min(1, Double(p.xpInto) / Double(p.xpNeeded))
    }

    // MARK: - Completion rate (last N days)

    /// Fraction of the last `window` days that had at least one completion.
    static func completionRate(completionDays: Set<Date>, window: Int = 7, now: Date = Date()) -> Double {
        guard window > 0 else { return 0 }
        let today = DateUtils.startOfDay(now)
        var hit = 0
        for offset in 0..<window {
            let day = DateUtils.adding(days: -offset, to: today)
            if completionDays.contains(DateUtils.startOfDay(day)) { hit += 1 }
        }
        return Double(hit) / Double(window)
    }

    // MARK: - Mood

    /// Derived mood from recent completion rate + current (decayed) energy.
    static func mood(completionRate7d: Double, energy: Int) -> CompanionMood {
        let e = clampEnergy(energy)
        if e <= 20 { return .needsYou }
        if e <= 40 { return .sleepy }
        if completionRate7d >= 0.6 && e >= 60 { return .thriving }
        return .content
    }

    /// A calm, varied mood line for the companion to "say".
    static func moodLine(_ mood: CompanionMood, name: String) -> String {
        switch mood {
        case .thriving:
            return "\(name) is glowing — thank you for showing up."
        case .content:
            return "\(name) feels settled and warm beside you."
        case .sleepy:
            return "\(name) is a little drowsy. A small kindness would help."
        case .needsYou:
            return "\(name) has been waiting. One gentle step is enough."
        }
    }

    // MARK: - Streaks

    /// Current and longest streak of consecutive days containing ≥1 completion.
    static func streaks(completionDays: Set<Date>, now: Date = Date()) -> (current: Int, longest: Int) {
        guard !completionDays.isEmpty else { return (0, 0) }
        let normalized = Set(completionDays.map { DateUtils.startOfDay($0) })

        // Current streak: walk back from today (or yesterday if today not yet done).
        let today = DateUtils.startOfDay(now)
        var current = 0
        var cursor = today
        if !normalized.contains(today) {
            // Allow streak to still count if yesterday was done (today not over yet).
            cursor = DateUtils.adding(days: -1, to: today)
        }
        while normalized.contains(cursor) {
            current += 1
            cursor = DateUtils.adding(days: -1, to: cursor)
        }

        // Longest streak across all recorded days.
        let sorted = normalized.sorted()
        var longest = 0
        var run = 0
        var prev: Date?
        for day in sorted {
            if let p = prev, DateUtils.daysBetween(p, day) == 1 {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            prev = day
        }
        return (current, max(longest, current))
    }

    // MARK: - Today progress

    /// Fraction of today's target met. Guards against zero target.
    static func dailyProgressFraction(completedToday: Int, target: Int) -> Double {
        let t = max(1, target)
        return min(1, Double(completedToday) / Double(t))
    }

    // MARK: - Awarding a completion

    struct CompletionAward {
        let pebbles: Int
        let energy: Int
        let xp: Int
    }

    /// The reward for completing a goal. XP scales with the goal's energy reward.
    static func award(for goal: SelfCareGoal) -> CompletionAward {
        CompletionAward(
            pebbles: max(0, goal.pebbleReward),
            energy: max(0, goal.energyReward),
            xp: max(1, goal.energyReward) // simple, predictable XP source
        )
    }
}
