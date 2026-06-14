import Foundation
import SwiftData

/// A completed-game record for the Stats screen.
@Model
final class GameRecord {
    var date: Date
    /// Stored as `GameResultKind.rawValue` (win/loss/draw).
    var resultRaw: String
    var vsComputer: Bool
    var computerLevel: Int
    var moveCount: Int

    init(date: Date = Date(),
         result: GameResultKind = .draw,
         vsComputer: Bool = true,
         computerLevel: Int = 2,
         moveCount: Int = 0) {
        self.date = date
        self.resultRaw = result.rawValue
        self.vsComputer = vsComputer
        self.computerLevel = computerLevel
        self.moveCount = moveCount
    }

    var result: GameResultKind {
        get { GameResultKind(rawValue: resultRaw) ?? .draw }
        set { resultRaw = newValue.rawValue }
    }
}
