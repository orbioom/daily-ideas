import Foundation

/// Best-score bookkeeping backed by UserDefaults. Classic keeps a single best; Daily keeps
/// a best per yyyyMMdd key plus a record of which days were played (for the streak/calendar).
enum BestScores {
    private static let classicKey = "best.classic"
    private static let dailyPrefix = "best.daily."
    private static let playedDaysKey = "playedDailyDays"

    static var classicBest: Int {
        UserDefaults.standard.integer(forKey: classicKey)
    }

    static func dailyBest(for dateKey: String) -> Int {
        UserDefaults.standard.integer(forKey: dailyPrefix + dateKey)
    }

    /// All daily date keys ("yyyyMMdd") the player has completed.
    static var playedDailyDays: Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: playedDaysKey) ?? []
        return Set(arr)
    }

    static func record(score: Int, mode: GameMode, dateKey: String) {
        let d = UserDefaults.standard
        switch mode {
        case .classic:
            if score > d.integer(forKey: classicKey) {
                d.set(score, forKey: classicKey)
            }
        case .daily:
            guard !dateKey.isEmpty else { return }
            let key = dailyPrefix + dateKey
            if score > d.integer(forKey: key) {
                d.set(score, forKey: key)
            }
            var days = playedDailyDays
            days.insert(dateKey)
            d.set(Array(days), forKey: playedDaysKey)
        }
    }

    /// Reset all best-score state (used by "Reset stats").
    static func reset() {
        let d = UserDefaults.standard
        d.removeObject(forKey: classicKey)
        d.removeObject(forKey: playedDaysKey)
        for key in d.dictionaryRepresentation().keys where key.hasPrefix(dailyPrefix) {
            d.removeObject(forKey: key)
        }
    }
}
