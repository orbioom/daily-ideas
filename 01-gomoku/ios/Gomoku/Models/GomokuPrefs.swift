import Foundation
import SwiftData

@Model
final class GomokuPrefs {
    var onboardingDone: Bool
    var difficulty: String      // "Easy", "Normal", "Hard"
    var humanColor: String      // "Black", "White"
    var hapticsEnabled: Bool
    var showCoordinates: Bool
    var boardTheme: String      // "Classic", "Dark", "Bamboo"

    init() {
        self.onboardingDone = false
        self.difficulty = "Normal"
        self.humanColor = "Black"
        self.hapticsEnabled = true
        self.showCoordinates = true
        self.boardTheme = "Classic"
    }
}
