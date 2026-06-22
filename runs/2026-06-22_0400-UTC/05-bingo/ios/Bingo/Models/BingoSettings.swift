import Foundation
import SwiftData

@Model
class BingoSettings {
    var id: UUID = UUID()
    var callDelaySeconds: Double = 5.0
    var speechEnabled: Bool = true
    var cardCount: Int = 2
    var hasCompletedOnboarding: Bool = false
    var hapticsEnabled: Bool = true
    var winPatterns: [String] = ["row", "column", "diagonal", "corners", "blackout"]
    var autoAdvance: Bool = false

    init() {
        self.id = UUID()
    }
}
