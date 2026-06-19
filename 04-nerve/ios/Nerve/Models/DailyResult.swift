import Foundation
import SwiftData

@Model
final class DailyResult {
    var id: UUID
    var dateString: String
    var guessCount: Int
    var isSolved: Bool
    var elapsedSeconds: Int

    init(dateString: String, guessCount: Int, isSolved: Bool, elapsedSeconds: Int) {
        self.id = UUID()
        self.dateString = dateString
        self.guessCount = guessCount
        self.isSolved = isSolved
        self.elapsedSeconds = elapsedSeconds
    }
}
