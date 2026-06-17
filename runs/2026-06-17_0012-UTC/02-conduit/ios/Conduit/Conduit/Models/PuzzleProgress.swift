import Foundation
import SwiftData

/// Per-puzzle progress record. One row per played puzzle id.
@Model
final class PuzzleProgress {
    @Attribute(.unique) var puzzleId: String
    var packRaw: String
    var size: Int
    var solved: Bool
    var perfect: Bool        // full 100% coverage
    var bestMoves: Int
    var bestSeconds: Int
    var lastPlayed: Date

    init(
        puzzleId: String,
        packRaw: String,
        size: Int,
        solved: Bool = false,
        perfect: Bool = false,
        bestMoves: Int = 0,
        bestSeconds: Int = 0,
        lastPlayed: Date = .now
    ) {
        self.puzzleId = puzzleId
        self.packRaw = packRaw
        self.size = size
        self.solved = solved
        self.perfect = perfect
        self.bestMoves = bestMoves
        self.bestSeconds = bestSeconds
        self.lastPlayed = lastPlayed
    }

    var pack: PackID { PackID(rawValue: packRaw) ?? .starter }
}
