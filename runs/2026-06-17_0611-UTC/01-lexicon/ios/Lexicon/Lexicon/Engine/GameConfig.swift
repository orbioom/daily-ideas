import Foundation

/// A fully-resolved description of a game to play: mode, length, the (already
/// chosen) answer, the puzzle date, and the stable saved key. Knows how to mint a
/// fresh `GameViewModel`.
struct GameConfig: Identifiable, Hashable {
    let mode: GameMode
    let wordLength: Int
    let answer: String       // lowercased; "" means unavailable
    let puzzleDate: Date
    let savedKey: String

    var id: String { savedKey + "|" + answer }

    func makeViewModel() -> GameViewModel {
        GameViewModel(
            mode: mode,
            wordLength: wordLength,
            answer: answer,
            puzzleDate: puzzleDate,
            savedKey: savedKey
        )
    }

    /// For Practice replays: pick a new random answer of the same length, keyed
    /// under the same "practice" saved key. Returns nil for non-practice configs.
    func makeFreshPracticeViewModel() -> GameViewModel? {
        guard mode == .practice else { return nil }
        let pool = WordLists.answers(length: wordLength)
        guard !pool.isEmpty else { return nil }
        let newAnswer = pool.randomElement() ?? answer
        return GameViewModel(
            mode: .practice,
            wordLength: wordLength,
            answer: newAnswer,
            puzzleDate: .now,
            savedKey: savedKey
        )
    }

    // MARK: - Factories

    /// Today's daily puzzle for the default length 5.
    static func daily(length: Int = 5, date: Date = .now) -> GameConfig {
        let day = DailyPuzzle.startOfDay(date)
        return GameConfig(
            mode: .daily,
            wordLength: length,
            answer: DailyPuzzle.answer(for: day, length: length),
            puzzleDate: day,
            savedKey: DailyPuzzle.savedKey(mode: .daily, date: day, length: length)
        )
    }

    /// A past daily puzzle (archive).
    static func archive(date: Date, length: Int = 5) -> GameConfig {
        let day = DailyPuzzle.startOfDay(date)
        return GameConfig(
            mode: .archive,
            wordLength: length,
            answer: DailyPuzzle.answer(for: day, length: length),
            puzzleDate: day,
            savedKey: DailyPuzzle.savedKey(mode: .archive, date: day, length: length)
        )
    }

    /// A practice game with a random answer of the given length.
    static func practice(length: Int) -> GameConfig {
        let pool = WordLists.answers(length: length)
        let answer = pool.randomElement() ?? ""
        return GameConfig(
            mode: .practice,
            wordLength: length,
            answer: answer,
            puzzleDate: .now,
            savedKey: DailyPuzzle.savedKey(mode: .practice, date: .now, length: length)
        )
    }
}
