import Foundation
import SwiftData

/// How a game was played.
enum GameMode: String, Codable, CaseIterable {
    case classic
    case daily

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .daily: return "Daily"
        }
    }
}

/// A completed (or abandoned-then-ended) game, written on game-over or win.
@Model
final class GameRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var boardSize: Int
    var score: Int
    var highestTile: Int
    var won: Bool
    var moves: Int
    var durationSeconds: Int
    /// Stored as the raw value of `GameMode` for forward compatibility.
    var modeRaw: String

    init(id: UUID = UUID(),
         date: Date = Date(),
         boardSize: Int,
         score: Int,
         highestTile: Int,
         won: Bool,
         moves: Int,
         durationSeconds: Int,
         mode: GameMode) {
        self.id = id
        self.date = date
        self.boardSize = boardSize
        self.score = score
        self.highestTile = highestTile
        self.won = won
        self.moves = moves
        self.durationSeconds = durationSeconds
        self.modeRaw = mode.rawValue
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .classic }
}
