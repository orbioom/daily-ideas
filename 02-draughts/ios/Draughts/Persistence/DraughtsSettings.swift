import SwiftData
import Foundation

@Model
final class DraughtsSettings {
    var difficulty: String = "medium"
    var humanPlaysRed: Bool = true
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true
    var isPro: Bool = false

    init() {}

    var difficultyEnum: Difficulty {
        get { Difficulty(rawValue: difficulty) ?? .medium }
        set { difficulty = newValue.rawValue }
    }
}
