import SwiftUI

enum NimbleTheme {
    static let background = Color("NimbleBackground")

    // Game colors
    static let gameBlue   = Color("GameBlue")
    static let gameOrange = Color("GameOrange")
    static let gameGreen  = Color("GameGreen")
    static let gamePink   = Color("GamePink")
    static let gameYellow = Color("GameYellow")

    static func gameColor(for type: GameType) -> Color {
        switch type {
        case .memoryGrid:  return gameBlue
        case .quickMath:   return gameOrange
        case .wordFlash:   return gameGreen
        case .patternGame: return gamePink
        case .reactionGame:return gameYellow
        }
    }

    static let scoreGood  = Color.green
    static let scoreOk    = Color.orange
    static let scoreBad   = Color.red

    static func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return scoreGood }
        if score >= 40 { return scoreOk }
        return scoreBad
    }
}
