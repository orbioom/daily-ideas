import SwiftUI

enum HuntTheme {
    // Background colors
    static let background = Color("HuntDark")
    static let cardBackground = Color(red: 0.12, green: 0.28, blue: 0.16)
    static let tileBackground = Color("HuntGreen")
    static let tileSelected = Color(red: 0.2, green: 0.75, blue: 0.3)
    static let tileHighlight = Color(red: 0.9, green: 0.75, blue: 0.1)
    static let pathColor = Color(red: 0.3, green: 0.9, blue: 0.4)

    // Text
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.6, green: 0.85, blue: 0.65)
    static let accent = Color("AccentColor")

    // Word bank
    static let validWord = Color(red: 0.15, green: 0.45, blue: 0.25)
    static let invalidWord = Color(red: 0.55, green: 0.12, blue: 0.12)

    // Timer
    static let timerNormal = Color(red: 0.2, green: 0.8, blue: 0.35)
    static let timerWarning = Color(red: 0.9, green: 0.6, blue: 0.1)
    static let timerDanger = Color(red: 0.9, green: 0.2, blue: 0.2)

    static func timerColor(for remaining: Int, total: Int) -> Color {
        let ratio = Double(remaining) / Double(total)
        if ratio > 0.4 { return timerNormal }
        if ratio > 0.2 { return timerWarning }
        return timerDanger
    }

    // Typography
    static func tileFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}
