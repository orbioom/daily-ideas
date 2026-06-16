import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Furlong's visual identity: highway-sign green, ledger-clean surfaces,
/// crisp monospaced numerals for money & odometer figures.
enum Theme {
    /// MUST equal AccentColor in Assets (0x1F7A4D).
    static let accent = Color(hex: 0x1F7A4D)
    static let accentSoft = Color.dyn(0xE3F1E9, 0x16352A)

    static let bg = Color.dyn(0xF5F7F4, 0x101512)
    static let surface = Color.dyn(0xFFFFFF, 0x1A211C)
    static let surfaceAlt = Color.dyn(0xEFF2ED, 0x222B25)

    static let ink = Color.dyn(0x16201A, 0xF1F5F1)
    static let inkSoft = Color.dyn(0x5C6A60, 0x9BA89F)
    static let hairline = Color.dyn(0xE2E7E1, 0x2C352E)

    static let good = Color.dyn(0x1F7A4D, 0x4FC587)
    static let warn = Color.dyn(0xB8761A, 0xE0A640)
    static let bad = Color.dyn(0xB42318, 0xF87166)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x1F7A4D), Color(hex: 0x176B43), Color(hex: 0x0F4F31)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing)

    // Category accent palette (kept readable in both modes via fixed mid-tones).
    static let palette: [Color] = [
        Color(hex: 0x1F7A4D), Color(hex: 0x2D7CC4), Color(hex: 0xC2761C),
        Color(hex: 0x8E55C8), Color(hex: 0xCB4B4B), Color(hex: 0x14998A),
        Color(hex: 0xB6326E), Color(hex: 0x5A6B3E), Color(hex: 0x5567D6)
    ]

    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 10

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// Monospaced numerals for money & odometer — a deliberate ledger cue.
    static func mono(_ s: CGFloat, _ w: Font.Weight = .semibold) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }
}
