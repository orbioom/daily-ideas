import SwiftUI

enum AnteTheme {
    // Felt table
    static let feltGreen = Color(red: 0.12, green: 0.28, blue: 0.18)
    static let feltGreenLight = Color(red: 0.15, green: 0.34, blue: 0.22)
    static let feltGreenDark = Color(red: 0.08, green: 0.20, blue: 0.12)

    // Gold accent
    static let gold = Color(red: 0.831, green: 0.627, blue: 0.090)
    static let goldLight = Color(red: 0.95, green: 0.80, blue: 0.35)
    static let goldDark = Color(red: 0.60, green: 0.44, blue: 0.04)

    // Card back
    static let cardBack = Color(red: 0.20, green: 0.40, blue: 0.70)
    static let cardBackGreen = Color(red: 0.10, green: 0.45, blue: 0.20)
    static let cardBackRed = Color(red: 0.65, green: 0.10, blue: 0.15)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.75)
    static let textMuted = Color.white.opacity(0.50)

    // UI surfaces
    static let surface = Color.white.opacity(0.10)
    static let surfaceRaised = Color.white.opacity(0.16)

    static func cardBackColor(for name: String) -> Color {
        switch name {
        case "green": return cardBackGreen
        case "red": return cardBackRed
        default: return cardBack
        }
    }
}
