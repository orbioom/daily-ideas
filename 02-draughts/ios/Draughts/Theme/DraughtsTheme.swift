import SwiftUI

enum DraughtsTheme {
    static let background = Color(red: 0.15, green: 0.10, blue: 0.06)
    static let lightSquare = Color(red: 0.85, green: 0.72, blue: 0.55)
    static let darkSquare = Color(red: 0.42, green: 0.28, blue: 0.16)
    static let redPiece = Color(red: 0.85, green: 0.15, blue: 0.10)
    static let blackPiece = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let gold = Color(red: 0.83, green: 0.69, blue: 0.22)
    static let text = Color.white

    // Additional semantic colors
    static let validMoveDot = Color(red: 0.25, green: 0.80, blue: 0.35).opacity(0.85)
    static let selectedHighlight = Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.75)
    static let lastMoveHighlight = Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.35)
    static let cardBackground = Color(red: 0.20, green: 0.13, blue: 0.08)
    static let separatorColor = Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.25)
}
