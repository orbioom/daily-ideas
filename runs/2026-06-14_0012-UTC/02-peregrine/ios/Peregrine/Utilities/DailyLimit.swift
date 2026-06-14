import Foundation

/// Free-tier quiz cap (3 graded quizzes per calendar day; the daily challenge is
/// always free and excluded). Persisted in UserDefaults so it survives relaunch.
/// Pro removes the cap entirely.
enum DailyLimit {
    static let freeQuota = 3

    private static let countKey = "freeQuizCount"
    private static let dayKey = "freeQuizDay"

    private static func todayKey(_ now: Date = Date()) -> String {
        QuizEngine.dailyKey(for: now)
    }

    /// Quizzes used today (resets automatically when the day changes).
    static func usedToday(_ defaults: UserDefaults = .standard, now: Date = Date()) -> Int {
        let storedDay = defaults.string(forKey: dayKey)
        guard storedDay == todayKey(now) else { return 0 }
        return defaults.integer(forKey: countKey)
    }

    static func remaining(isPro: Bool, _ defaults: UserDefaults = .standard, now: Date = Date()) -> Int {
        if isPro { return Int.max }
        return max(0, freeQuota - usedToday(defaults, now: now))
    }

    static func canStart(isPro: Bool, _ defaults: UserDefaults = .standard, now: Date = Date()) -> Bool {
        isPro || remaining(isPro: false, defaults, now: now) > 0
    }

    /// Record that a graded quiz was started/completed today.
    static func consume(isPro: Bool, _ defaults: UserDefaults = .standard, now: Date = Date()) {
        guard !isPro else { return }
        let key = todayKey(now)
        if defaults.string(forKey: dayKey) != key {
            defaults.set(key, forKey: dayKey)
            defaults.set(0, forKey: countKey)
        }
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
    }
}
