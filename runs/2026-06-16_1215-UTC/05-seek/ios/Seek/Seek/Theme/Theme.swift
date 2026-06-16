import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A color that resolves differently in light and dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { trait in
            let h = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Seek's visual identity: a calm, warm terracotta accent over soft paper backgrounds.
enum Theme {
    /// Must match the AccentColor asset (0xE0654E).
    static let accent = Color(hex: 0xE0654E)
    static let accentDeep = Color.dyn(0xC24E39, 0xF07D67)

    static let bg = Color.dyn(0xFBF6F0, 0x15110F)
    static let surface = Color.dyn(0xFFFFFF, 0x231D1A)
    static let surfaceAlt = Color.dyn(0xF3EAE0, 0x2C2521)

    static let ink = Color.dyn(0x2A211C, 0xF6EFE9)
    static let inkSoft = Color.dyn(0x7A6B60, 0xB6A89D)
    static let hairline = Color.dyn(0xE7DACC, 0x39302B)

    static let good = Color.dyn(0x3E9E6E, 0x57C98E)
    static let warn = Color.dyn(0xC9892B, 0xE6B45A)
    static let bad = Color.dyn(0xC2473A, 0xE57F71)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xE0654E), Color(hex: 0xE89A52)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
}

/// A palette of selectable highlight tints for the word-search band.
enum HighlightTheme: String, CaseIterable, Identifiable {
    case terracotta = "Terracotta"
    case ocean = "Ocean"
    case meadow = "Meadow"
    case grape = "Grape"
    case sunset = "Sunset"

    var id: String { rawValue }

    /// Whether the theme requires Pro to use.
    var isPro: Bool {
        switch self {
        case .terracotta, .ocean: return false
        case .meadow, .grape, .sunset: return true
        }
    }

    var color: Color {
        switch self {
        case .terracotta: return Color(hex: 0xE0654E)
        case .ocean: return Color(hex: 0x3E86C9)
        case .meadow: return Color(hex: 0x4FA773)
        case .grape: return Color(hex: 0x8A63C9)
        case .sunset: return Color(hex: 0xE08A2E)
        }
    }
}
