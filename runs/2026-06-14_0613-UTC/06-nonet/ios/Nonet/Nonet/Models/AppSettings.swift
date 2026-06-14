import SwiftUI
import Combine

/// User preferences persisted in UserDefaults via @AppStorage. Small flags only — the
/// games themselves live in SwiftData. Exposed app-wide as an EnvironmentObject.
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("highlightPeers") var highlightPeers: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("highlightSameNumber") var highlightSameNumber: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("autoCandidateMode") var autoCandidateMode: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("mistakeLimitOn") var mistakeLimitOn: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("showTimer") var showTimer: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("conflictHighlight") var conflictHighlight: Bool = true {
        willSet { objectWillChange.send() }
    }

    /// Maximum mistakes before game-over when `mistakeLimitOn` is true.
    let mistakeLimit = 3
}

/// Daily-streak bookkeeping kept in UserDefaults (small flags, not game state).
enum StreakStore {
    private static let lastKey = "dailyStreakLastDateKey"
    private static let currentKey = "dailyStreakCurrent"
    private static let longestKey = "dailyStreakLongest"

    static var current: Int { UserDefaults.standard.integer(forKey: currentKey) }
    static var longest: Int { UserDefaults.standard.integer(forKey: longestKey) }
    static var lastDateKey: String { UserDefaults.standard.string(forKey: lastKey) ?? "" }

    /// Records that today's daily was solved. Increments the streak if yesterday's daily
    /// was solved, otherwise resets to 1. Idempotent for the same day.
    static func recordDailySolved(date: Date = Date(), calendar: Calendar = .current) {
        let todayKey = DailySeed.dateKey(for: date, calendar: calendar)
        if lastDateKey == todayKey { return } // already counted today

        var newCurrent = 1
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date) {
            let yKey = DailySeed.dateKey(for: yesterday, calendar: calendar)
            if lastDateKey == yKey {
                newCurrent = current + 1
            }
        }
        UserDefaults.standard.set(newCurrent, forKey: currentKey)
        UserDefaults.standard.set(todayKey, forKey: lastKey)
        if newCurrent > longest {
            UserDefaults.standard.set(newCurrent, forKey: longestKey)
        }
    }

    /// True if today's daily is already marked solved.
    static func isDailySolved(date: Date = Date(), calendar: Calendar = .current) -> Bool {
        lastDateKey == DailySeed.dateKey(for: date, calendar: calendar)
    }

    /// If the streak was broken (last solved older than yesterday), reflect that as 0
    /// for display purposes without mutating storage.
    static func displayCurrent(date: Date = Date(), calendar: Calendar = .current) -> Int {
        let todayKey = DailySeed.dateKey(for: date, calendar: calendar)
        if lastDateKey == todayKey { return current }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date) {
            let yKey = DailySeed.dateKey(for: yesterday, calendar: calendar)
            if lastDateKey == yKey { return current }
        }
        return 0
    }
}
