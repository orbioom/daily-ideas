import Foundation
import SwiftData

@Model
class BingoGame {
    var id: UUID = UUID()
    var date: Date = Date()
    var gameType: String = "number"
    var packName: String = "Classic Number"
    var calledItems: [String] = []
    var isComplete: Bool = false
    var callCount: Int = 0
    var winnerCardIndex: Int = -1
    var winPattern: String = ""

    init(gameType: String, packName: String) {
        self.id = UUID()
        self.date = Date()
        self.gameType = gameType
        self.packName = packName
        self.calledItems = []
        self.isComplete = false
        self.callCount = 0
        self.winnerCardIndex = -1
        self.winPattern = ""
    }
}
