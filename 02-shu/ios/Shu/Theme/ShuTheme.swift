import SwiftUI

enum ShuTheme {
    // MARK: - Background Colors
    static let darkNavy    = Color(red: 0.05, green: 0.07, blue: 0.14)
    static let cardBg      = Color(red: 0.09, green: 0.13, blue: 0.22)
    static let surfaceBg   = Color(red: 0.12, green: 0.17, blue: 0.28)

    // MARK: - Accent Colors
    static let gold        = Color(red: 0.95, green: 0.78, blue: 0.35)
    static let goldDim     = Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.3)

    // MARK: - Text Colors
    static let subtleText  = Color.white.opacity(0.5)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.75)

    // MARK: - Feedback Colors
    static let correctGreen = Color(red: 0.27, green: 0.83, blue: 0.44)
    static let wrongRed     = Color(red: 0.96, green: 0.35, blue: 0.35)
    static let warningAmber = Color(red: 0.96, green: 0.65, blue: 0.14)

    // MARK: - Tone Colors (Tone 1-4)
    /// Tone 1 – flat / high: sky blue
    /// Tone 2 – rising: emerald green
    /// Tone 3 – dipping: coral red
    /// Tone 4 – falling: steel gray
    /// Tone 5 – neutral: muted gold
    static let toneColors: [Color] = [
        Color(red: 0.35, green: 0.70, blue: 0.96), // 1 – high-level (blue)
        Color(red: 0.27, green: 0.83, blue: 0.44), // 2 – rising (green)
        Color(red: 0.96, green: 0.35, blue: 0.35), // 3 – dipping (red)
        Color(red: 0.70, green: 0.70, blue: 0.75), // 4 – falling (gray)
    ]

    static func toneColor(for tone: Int) -> Color {
        guard tone >= 1, tone <= 4 else {
            return Color.white.opacity(0.6) // neutral / tone 5
        }
        return toneColors[tone - 1]
    }

    // MARK: - Typography
    static func characterFont(size: CGFloat = 80) -> Font {
        .system(size: size, weight: .thin, design: .default)
    }

    static func pinyinFont(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func labelFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // MARK: - Corner Radius
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 12
    static let chipRadius: CGFloat = 8

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.4)
}
