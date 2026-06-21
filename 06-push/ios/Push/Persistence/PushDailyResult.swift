import Foundation
import SwiftData

@Model
final class PushDailyResult {
    var dateString: String
    var levelId: Int
    var solved: Bool
    var moves: Int

    init(dateString: String, levelId: Int, solved: Bool, moves: Int) {
        self.dateString = dateString
        self.levelId = levelId
        self.solved = solved
        self.moves = moves
    }
}
