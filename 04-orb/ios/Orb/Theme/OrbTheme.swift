import SwiftUI

enum OrbTheme {
    static let background = Color(red: 0.031, green: 0.020, blue: 0.157)  // #080520
    static let accent = Color(red: 0.0, green: 0.831, blue: 1.0)          // #00D4FF
    static let surface = Color(red: 0.08, green: 0.06, blue: 0.25)
    static let surfaceAlt = Color(red: 0.12, green: 0.09, blue: 0.35)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let starGold = Color(red: 1.0, green: 0.84, blue: 0.0)

    static func bubbleGradient(for color: Color) -> [Color] {
        [color.opacity(1.0), color.opacity(0.6)]
    }
}

extension View {
    func orbBackground() -> some View {
        self.background(OrbTheme.background.ignoresSafeArea())
    }
}
