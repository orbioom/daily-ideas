import SwiftUI

enum HoopTheme {
    // Backgrounds
    static let darkBg       = Color(red: 0.08, green: 0.06, blue: 0.06)
    static let cardBg       = Color(red: 0.13, green: 0.11, blue: 0.10)
    static let court        = Color(red: 0.60, green: 0.40, blue: 0.20)

    // Accent
    static let orange       = Color(red: 0.95, green: 0.45, blue: 0.10)

    // Text
    static let subtleText   = Color.white.opacity(0.5)

    // Team colors
    static let teamAColor   = Color(red: 0.20, green: 0.40, blue: 0.80) // blue
    static let teamBColor   = Color(red: 0.80, green: 0.15, blue: 0.15) // red

    // Helpers
    static func teamColor(for team: String) -> Color {
        team == "A" ? teamAColor : teamBColor
    }

    // Typography helpers
    static let scoreFont    = Font.system(size: 72, weight: .black, design: .rounded)
    static let quarterFont  = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let timerFont    = Font.system(size: 36, weight: .bold, design: .monospaced)
    static let labelFont    = Font.system(size: 13, weight: .medium)
    static let buttonFont   = Font.system(size: 15, weight: .bold, design: .rounded)
}

extension View {
    func hoopCard() -> some View {
        self
            .background(HoopTheme.cardBg)
            .cornerRadius(16)
    }
}
