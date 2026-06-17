import Foundation

/// Builds a deterministic daily puzzle from the calendar date. The same date
/// always produces the same base word and the same crossword layout.
enum DailyPuzzle {

    /// The synthetic Level for a given date (id encodes the date key).
    static func level(for date: Date = .now) -> Level {
        let words = LevelData.dailyBaseWords
        let base: String
        if words.isEmpty {
            base = "GARDEN"
        } else {
            let idx = ((DateKey.dayNumber(for: date) % words.count) + words.count) % words.count
            base = words[idx]
        }
        let targets = LevelData.dailyTargets[base] ?? [base]
        let key = DateKey.key(for: date)
        return Level(
            id: "daily-\(key)",
            title: "Daily Puzzle",
            baseWord: base,
            targetWords: targets,
            extraBonusWords: []
        )
    }
}
