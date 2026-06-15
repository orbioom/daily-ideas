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

/// Tetra's visual identity: tactile candy-arcade — a deep playful board with warm rounded tiles.
enum Theme {
    // Backgrounds — deep, playful, calm.
    static let bg = Color.dyn(0xFBF3E9, 0x14110D)
    static let surface = Color.dyn(0xFFFFFF, 0x211B14)
    static let surfaceAlt = Color.dyn(0xF3E7D6, 0x2C241A)

    /// The recessed board frame — the "tray" the tiles sit in.
    static let boardTray = Color.dyn(0xE7D6BF, 0x2A2118)
    /// An empty cell within the board.
    static let boardCell = Color.dyn(0xF4E8D6, 0x342A1E)

    // Ink (text)
    static let ink = Color.dyn(0x2A2014, 0xF6EEE2)
    static let inkSoft = Color.dyn(0x6E5C45, 0xCBB99F)
    static let inkFaint = Color.dyn(0x9C8869, 0x8A765A)

    // Accent — warm orange (matches AccentColor 0xF29A4E)
    static let accent = Color(hex: 0xF29A4E)
    static let accentSoft = Color.dyn(0xFBE3C8, 0x3E2E1A)
    static let accentDeep = Color.dyn(0xD97A24, 0xF4B473)

    // Lines & status
    static let hairline = Color.dyn(0xEAD8C0, 0x352B1F)
    static let good = Color.dyn(0x2E9E6B, 0x4FD39A)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    /// A warm gradient for hero surfaces (paywall, onboarding, win overlay).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xF7B267), Color(hex: 0xF29A4E), Color(hex: 0xE76F51)],
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

    // MARK: - Tile color ramp

    /// Per-value tile fill — each power of two gets its own warm→cool hue so the
    /// board reads at a glance. Returns (background, foreground) for WCAG-AA legibility.
    static func tileColors(forValue value: Int) -> (fill: Color, ink: Color) {
        switch value {
        case 2:    return (Color.dyn(0xF7ECDB, 0x3A3024), Color.dyn(0x6E5C45, 0xE9DCC8))
        case 4:    return (Color.dyn(0xF6E2C0, 0x4A3A22), Color.dyn(0x6E5C45, 0xF1E3C9))
        case 8:    return (Color.dyn(0xF7B267, 0xC97E2E), Color(hex: 0xFFFFFF))
        case 16:   return (Color.dyn(0xF29A4E, 0xCF6F26), Color(hex: 0xFFFFFF))
        case 32:   return (Color.dyn(0xEF7C44, 0xC85A22), Color(hex: 0xFFFFFF))
        case 64:   return (Color.dyn(0xE76F51, 0xC24C32), Color(hex: 0xFFFFFF))
        case 128:  return (Color.dyn(0xE05780, 0xB83A60), Color(hex: 0xFFFFFF))
        case 256:  return (Color.dyn(0xC44FA0, 0x9C3580), Color(hex: 0xFFFFFF))
        case 512:  return (Color.dyn(0x9B5DE5, 0x7A3FC0), Color(hex: 0xFFFFFF))
        case 1024: return (Color.dyn(0x5C7CFA, 0x3F5BD6), Color(hex: 0xFFFFFF))
        case 2048: return (Color.dyn(0x2EBFA5, 0x1E9C86), Color(hex: 0xFFFFFF))
        case 4096: return (Color.dyn(0x2E9E6B, 0x1E7E52), Color(hex: 0xFFFFFF))
        default:   return (Color.dyn(0x1F2937, 0xE9DCC8), Color.dyn(0xFFFFFF, 0x1F2937))
        }
    }
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
