import SwiftUI

// MARK: - Color helpers (shared Orbioom convention)

extension Color {
    /// Create a Color from a hex string such as "2E86C1" or "#2E86C1".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255.0
            g = Double((value & 0x00FF00) >> 8) / 255.0
            b = Double(value & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255.0
            g = Double((value & 0x00FF0000) >> 16) / 255.0
            b = Double((value & 0x0000FF00) >> 8) / 255.0
            a = Double(value & 0x000000FF) / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Dynamic color resolving differently for light and dark appearances.
    static func dyn(_ light: Color, _ dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Theme tokens

enum Theme {
    /// Bright azure brand accent (2E86C1).
    static let accent = Color(hex: "2E86C1")
    static let accentDeep = Color(hex: "1B5E8C")
    static let accentSoft = Color(hex: "5DADE2")

    /// App background — clean boarding-pass white / deep slate.
    static let background = Color.dyn(Color(hex: "F4F8FB"), Color(hex: "0E141B"))
    /// Elevated surfaces (cards, sheets).
    static let surface = Color.dyn(Color(hex: "FFFFFF"), Color(hex: "192431"))
    /// Slightly recessed surface (grouped rows).
    static let surfaceAlt = Color.dyn(Color(hex: "EAF2F8"), Color(hex: "121B25"))

    static let textPrimary = Color.dyn(Color(hex: "15212B"), Color(hex: "F2F7FB"))
    static let textSecondary = Color.dyn(Color(hex: "5A6B79"), Color(hex: "9FB2C2"))

    static let separator = Color.dyn(Color(hex: "D7E3ED"), Color(hex: "26333F"))

    static let success = Color(hex: "27AE60")
    static let warning = Color(hex: "E67E22")
    static let danger = Color(hex: "C0392B")

    // Rounded brand font helpers
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    static let cornerLarge: CGFloat = 22
    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 10

    /// Deterministic cover gradient from a stored hue (0...1).
    static func coverGradient(hue: Double) -> LinearGradient {
        let h = hue.truncatingRemainder(dividingBy: 1.0)
        let safeH = h < 0 ? h + 1.0 : h
        let c1 = Color(hue: safeH, saturation: 0.62, brightness: 0.78)
        let c2 = Color(hue: (safeH + 0.08).truncatingRemainder(dividingBy: 1.0),
                       saturation: 0.74, brightness: 0.55)
        return LinearGradient(colors: [c1, c2],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
}
