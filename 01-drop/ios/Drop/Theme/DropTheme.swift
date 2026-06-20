import SwiftUI

enum DropTheme {
    static let accent = Color("AccentColor")
    static let navy = Color("DropNavy")
    static let humanColor = Color(red: 0.85, green: 0.15, blue: 0.15)
    static let cpuColor = Color(red: 0.95, green: 0.78, blue: 0.05)
    static let slotColor = Color(red: 0.12, green: 0.18, blue: 0.45)
    static let boardColor = Color(red: 0.10, green: 0.14, blue: 0.38)

    static func playerColor(_ player: DropPlayer) -> Color {
        player == .human ? humanColor : cpuColor
    }

    static func playerName(_ player: DropPlayer) -> String {
        player == .human ? "You" : "CPU"
    }

    static func difficultyName(_ level: Int) -> String {
        switch level {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return "Medium"
        }
    }
}
