import Foundation

/// A navigation destination that fully describes a game to start. Hashable so it
/// can drive `navigationDestination(for:)`.
struct GameRoute: Hashable {
    enum Source: Hashable {
        case standard(String)   // difficulty rawValue
        case daily(String)      // dateKey
    }
    let source: Source
    let rows: Int
    let cols: Int
    let mines: Int
    let noGuess: Bool
    let seed: UInt64?
    /// When true, resume the persisted game rather than starting fresh.
    let resume: Bool

    static func standard(_ difficulty: Difficulty, config: BoardConfig, noGuess: Bool) -> GameRoute {
        GameRoute(source: .standard(difficulty.rawValue),
                  rows: config.rows, cols: config.cols, mines: config.mines,
                  noGuess: noGuess, seed: nil, resume: false)
    }

    static func daily(dateKey: String, config: BoardConfig, seed: UInt64) -> GameRoute {
        GameRoute(source: .daily(dateKey),
                  rows: config.rows, cols: config.cols, mines: config.mines,
                  noGuess: true, seed: seed, resume: false)
    }

    static func resume(_ saved: SavedGame) -> GameRoute {
        GameRoute(source: .standard(saved.difficultyRaw),
                  rows: saved.rows, cols: saved.cols, mines: saved.mines,
                  noGuess: saved.noGuess, seed: nil, resume: true)
    }
}
