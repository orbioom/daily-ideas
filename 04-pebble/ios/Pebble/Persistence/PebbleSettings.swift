import SwiftData
import Foundation

@Model
final class PebbleSettings {
    var aiDifficultyRaw: String = "medium"
    var hapticsEnabled: Bool = true
    var seedsPerPit: Int = 4
    var isPro: Bool = false
    var gameModeRaw: String = "vsAI"

    init() {}

    var aiDifficulty: AIDifficulty {
        get { AIDifficulty(rawValue: aiDifficultyRaw) ?? .medium }
        set { aiDifficultyRaw = newValue.rawValue }
    }

    var gameMode: PebbleGame.GameMode {
        get { PebbleGame.GameMode(rawValue: gameModeRaw) ?? .vsAI }
        set { gameModeRaw = newValue.rawValue }
    }
}
