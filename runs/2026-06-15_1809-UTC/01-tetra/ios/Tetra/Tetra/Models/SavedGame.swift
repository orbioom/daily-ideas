import Foundation
import SwiftData

/// The one active, resumable game for a given board size. The grid is stored as
/// JSON-encoded `Data` so it survives relaunch; decode failures fall back to a
/// fresh board rather than crashing.
@Model
final class SavedGame {
    @Attribute(.unique) var boardSize: Int
    var gridData: Data
    var score: Int
    var best: Int
    var moves: Int
    /// Seed for the daily challenge (0 for a normal classic game).
    var seed: Int
    var startedAt: Date
    /// Elapsed seconds accumulated so far in this game.
    var elapsedSeconds: Int
    /// Whether the player has crossed 2048 and chosen to keep going.
    var continuedAfterWin: Bool
    var modeRaw: String

    init(boardSize: Int,
         grid: [[Int]],
         score: Int,
         best: Int,
         moves: Int,
         seed: Int,
         startedAt: Date = Date(),
         elapsedSeconds: Int = 0,
         continuedAfterWin: Bool = false,
         mode: GameMode = .classic) {
        self.boardSize = boardSize
        self.gridData = SavedGame.encode(grid: grid)
        self.score = score
        self.best = best
        self.moves = moves
        self.seed = seed
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.continuedAfterWin = continuedAfterWin
        self.modeRaw = mode.rawValue
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .classic }

    /// The decoded grid, or a fresh empty board on any decode failure.
    var grid: [[Int]] {
        get {
            if let decoded = try? JSONDecoder().decode([[Int]].self, from: gridData),
               !decoded.isEmpty {
                return decoded
            }
            return Array(repeating: Array(repeating: 0, count: boardSize), count: boardSize)
        }
        set {
            gridData = SavedGame.encode(grid: newValue)
        }
    }

    /// Encodes a grid to JSON, falling back to an empty `Data` on failure (never throws).
    static func encode(grid: [[Int]]) -> Data {
        (try? JSONEncoder().encode(grid)) ?? Data()
    }
}
