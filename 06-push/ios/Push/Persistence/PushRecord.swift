import Foundation
import SwiftData

@Model
final class PushRecord {
    var levelId: Int
    var packId: Int
    var bestMoves: Int
    var bestPushes: Int
    var completedAt: Date

    init(levelId: Int, packId: Int, bestMoves: Int, bestPushes: Int) {
        self.levelId = levelId
        self.packId = packId
        self.bestMoves = bestMoves
        self.bestPushes = bestPushes
        self.completedAt = Date()
    }
}
