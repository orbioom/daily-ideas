import SwiftUI

enum NovaTheme {
    static let skyBackground = Color(red: 0.04, green: 0.05, blue: 0.15)
    static let skyMid = Color(red: 0.07, green: 0.09, blue: 0.25)
    static let starWhite = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let starGold = Color(red: 1.0, green: 0.92, blue: 0.65)
    static let constellationLine = Color(red: 0.4, green: 0.55, blue: 0.85).opacity(0.45)
    static let cardBackground = Color(red: 0.08, green: 0.10, blue: 0.22)
    static let accent = Color(red: 0.45, green: 0.65, blue: 1.0)
    static let accentGold = Color(red: 1.0, green: 0.85, blue: 0.45)
    static let textPrimary = Color(red: 0.92, green: 0.94, blue: 1.0)
    static let textSecondary = Color(red: 0.55, green: 0.60, blue: 0.78)
    static let horizon = Color(red: 0.15, green: 0.25, blue: 0.45)
    static let planetColor = Color(red: 0.9, green: 0.75, blue: 0.35)

    static func starColor(bv: Double) -> Color {
        // B-V index to approximate color: negative=blue, 0=white, positive=orange/red
        if bv < -0.2 { return Color(red: 0.7, green: 0.8, blue: 1.0) }
        if bv < 0.1 { return Color(red: 0.9, green: 0.92, blue: 1.0) }
        if bv < 0.5 { return Color(red: 1.0, green: 0.97, blue: 0.9) }
        if bv < 1.0 { return Color(red: 1.0, green: 0.87, blue: 0.65) }
        return Color(red: 1.0, green: 0.65, blue: 0.45)
    }
}
