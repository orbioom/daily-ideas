import Foundation
import SwiftData

/// A single in-progress game so the player can resume after backgrounding or
/// relaunch. The board grid is encoded as Codable JSON in `boardJSON`.
@Model
final class SavedGame {
    var id: UUID
    var difficultyRaw: String
    var rows: Int
    var cols: Int
    var mines: Int
    var elapsedSec: Double
    var boardJSON: String
    var firstClickDone: Bool
    var noGuess: Bool
    var updatedAt: Date

    init(id: UUID = UUID(),
         difficultyRaw: String,
         rows: Int,
         cols: Int,
         mines: Int,
         elapsedSec: Double,
         boardJSON: String,
         firstClickDone: Bool,
         noGuess: Bool,
         updatedAt: Date = .now) {
        self.id = id
        self.difficultyRaw = difficultyRaw
        self.rows = rows
        self.cols = cols
        self.mines = mines
        self.elapsedSec = elapsedSec
        self.boardJSON = boardJSON
        self.firstClickDone = firstClickDone
        self.noGuess = noGuess
        self.updatedAt = updatedAt
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .custom
    }

    /// Decode the persisted engine, returning nil on any corruption.
    func decodedEngine() -> MineEngine? {
        guard let data = boardJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MineEngine.self, from: data)
    }
}
