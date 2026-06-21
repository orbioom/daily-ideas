import SwiftUI

enum FlopTheme {
    static let background = Color(red: 0.07, green: 0.13, blue: 0.07)
    static let felt = Color(red: 0.09, green: 0.17, blue: 0.09)
    static let card = Color(red: 0.13, green: 0.22, blue: 0.13)
    static let accent = Color(red: 0.35, green: 0.85, blue: 0.45)
    static let accentGold = Color(red: 1.0, green: 0.82, blue: 0.25)
    static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.92)
    static let textSecondary = Color(red: 0.60, green: 0.70, blue: 0.60)
    static let suitRed = Color(red: 0.85, green: 0.22, blue: 0.22)
    static let suitBlack = Color(red: 0.90, green: 0.90, blue: 0.90)
    static let correctGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let wrongRed = Color(red: 0.85, green: 0.3, blue: 0.3)
    static let neutralBlue = Color(red: 0.3, green: 0.55, blue: 0.85)
    static let positionColors: [PokerPosition: Color] = [
        .utg: Color(red: 0.8, green: 0.4, blue: 0.2),
        .mp: Color(red: 0.7, green: 0.6, blue: 0.2),
        .co: Color(red: 0.3, green: 0.7, blue: 0.4),
        .btn: Color(red: 0.3, green: 0.6, blue: 0.9),
        .sb: Color(red: 0.6, green: 0.3, blue: 0.8),
        .bb: Color(red: 0.8, green: 0.3, blue: 0.5),
    ]
}
