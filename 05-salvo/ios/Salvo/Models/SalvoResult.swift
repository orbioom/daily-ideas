import Foundation
import SwiftData

@Model
final class SalvoResult {
    var id: UUID = UUID()
    var date: Date = Date()
    var outcome: String = "loss"   // "win" or "loss"
    var shotsPlayer: Int = 0
    var shotsAI: Int = 0
    var difficulty: String = "Normal"

    init(outcome: String, shotsPlayer: Int, shotsAI: Int, difficulty: String) {
        self.outcome = outcome
        self.shotsPlayer = shotsPlayer
        self.shotsAI = shotsAI
        self.difficulty = difficulty
    }
}
