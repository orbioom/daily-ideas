import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Resolves a different hex per interface style so colors stay legible in light and dark.
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

/// Limn's visual identity: a quiet studio of graph paper. Cool teal accent on calm
/// paper backgrounds; the filled cells read as confident ink strokes.
enum Theme {
    // Backgrounds — light paper / deep teal-charcoal.
    static let bg = Color.dyn(0xEAF4F4, 0x06262B)
    static let surface = Color.dyn(0xFFFFFF, 0x0C3138)
    static let surfaceAlt = Color.dyn(0xDDEDED, 0x123C44)

    /// The recessed board frame the cells sit in.
    static let boardTray = Color.dyn(0xDDEDED, 0x0A2E34)
    /// An empty (unknown) cell within the board.
    static let boardCell = Color.dyn(0xFBFEFE, 0x0E353C)
    /// A cell the player has marked as definitely empty (crossed).
    static let boardCrossed = Color.dyn(0xEFF6F6, 0x0A2C32)
    /// A filled (inked) cell.
    static let boardFill = Color.dyn(0x0F4C5C, 0x9FE6DB)

    // Ink (text)
    static let ink = Color.dyn(0x0A2A2E, 0xEAF7F5)
    static let inkSoft = Color.dyn(0x3F6066, 0xA8C9C8)
    static let inkFaint = Color.dyn(0x789A9A, 0x6C8E8E)

    // Accent — teal (matches AccentColor 0x13B6A8)
    static let accent = Color(hex: 0x13B6A8)
    static let accentSoft = Color.dyn(0xCDEEEA, 0x0F4A47)
    static let accentDeep = Color.dyn(0x0E8C82, 0x4FD6C7)

    // Lines & status
    static let hairline = Color.dyn(0xCFE4E3, 0x16414A)
    /// The bolder grid divider every 5 cells.
    static let gridMajor = Color.dyn(0x9EC4C2, 0x2A5A60)
    static let gridMinor = Color.dyn(0xCFE4E3, 0x1B454D)
    static let good = Color.dyn(0x1E9E6B, 0x4FD39A)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    /// A cool gradient for hero surfaces (paywall, onboarding, win overlay).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x2AD0C0), Color(hex: 0x13B6A8), Color(hex: 0x0E8C82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

/// Card surface used across the app for a cohesive look.
struct CardBackground: ViewModifier {
    var fill: Color = Theme.surface
    var corner: CGFloat = Theme.corner
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(fill: Color = Theme.surface, corner: CGFloat = Theme.corner) -> some View {
        modifier(CardBackground(fill: fill, corner: corner))
    }
}
