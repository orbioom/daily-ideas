import Foundation
import SwiftData

/// A persisted game (in-progress or finished) so it can be resumed on relaunch.
@Model
final class SavedGame {
    /// Space-joined UCI moves from `startFEN`.
    var movesUCI: String
    var startFEN: String
    var createdAt: Date
    var updatedAt: Date
    /// Stored as `GameResultKind.rawValue`.
    var resultRaw: String
    var vsComputer: Bool
    var computerLevel: Int
    /// Stored as `HumanSide.rawValue`.
    var humanSideRaw: String

    init(movesUCI: String = "",
         startFEN: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         result: GameResultKind = .inProgress,
         vsComputer: Bool = true,
         computerLevel: Int = 2,
         humanSide: HumanSide = .white) {
        self.movesUCI = movesUCI
        self.startFEN = startFEN
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.resultRaw = result.rawValue
        self.vsComputer = vsComputer
        self.computerLevel = computerLevel
        self.humanSideRaw = humanSide.rawValue
    }

    var result: GameResultKind {
        get { GameResultKind(rawValue: resultRaw) ?? .inProgress }
        set { resultRaw = newValue.rawValue }
    }

    var humanSide: HumanSide {
        get { HumanSide(rawValue: humanSideRaw) ?? .white }
        set { humanSideRaw = newValue.rawValue }
    }

    /// The moves split into an array (empty entries removed).
    var moveList: [String] {
        movesUCI.split(separator: " ").map(String.init)
    }

    var aiLevel: AILevel {
        AILevel(rawValue: computerLevel) ?? .medium
    }
}
