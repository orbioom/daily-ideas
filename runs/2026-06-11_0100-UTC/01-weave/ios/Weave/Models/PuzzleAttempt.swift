import SwiftData
import Foundation

@Model
class PuzzleAttempt {
    var puzzleId: Int
    var date: Date
    var solved: Bool
    var solvedGroupIds: [Int]   // ids of PuzzleGroups solved in order
    var mistakesUsed: Int
    var gaveUp: Bool

    init(puzzleId: Int) {
        self.puzzleId = puzzleId
        self.date = Date()
        self.solved = false
        self.solvedGroupIds = []
        self.mistakesUsed = 0
        self.gaveUp = false
    }
}
