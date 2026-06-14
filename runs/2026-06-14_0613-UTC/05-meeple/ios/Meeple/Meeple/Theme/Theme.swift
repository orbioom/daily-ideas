import SwiftUI

// MARK: - Color hex + dynamic helpers

extension Color {
    /// Create a Color from a hex string like "E07A3E" or "#E07A3E" (also supports 8-digit ARGB).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 8: // AARRGGBB
            a = (value & 0xFF00_0000) >> 24
            r = (value & 0x00FF_0000) >> 16
            g = (value & 0x0000_FF00) >> 8
            b = value & 0x0000_00FF
        case 6: // RRGGBB
            a = 255
            r = (value & 0xFF0000) >> 16
            g = (value & 0x00FF00) >> 8
            b = value & 0x0000FF
        default:
            a = 255; r = 224; g = 122; b = 62 // fallback to accent base
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }

    /// Dynamic color resolving to `light` in light mode and `dark` in dark mode.
    static func dyn(_ light: Color, _ dark: Color) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Theme tokens

enum Theme {
    // Brand accent — warm amber / cardboard
    static let accent = Color(hex: "E07A3E")
    static let accentDeep = Color(hex: "C25E26")
    static let accentSoft = Color(hex: "F3C79A")

    // Backgrounds
    static let bg = Color.dyn(Color(hex: "FBF4EC"), Color(hex: "1A1512"))
    static let surface = Color.dyn(Color(hex: "FFFFFF"), Color(hex: "26201B"))
    static let surfaceAlt = Color.dyn(Color(hex: "F3E8DC"), Color(hex: "322A23"))

    // Text
    static let textPrimary = Color.dyn(Color(hex: "2C211A"), Color(hex: "F4EBE2"))
    static let textSecondary = Color.dyn(Color(hex: "6E5C4D"), Color(hex: "B6A695"))

    // Lines / accents
    static let hairline = Color.dyn(Color(hex: "E5D6C5"), Color(hex: "3C3229"))
    static let success = Color.dyn(Color(hex: "3F8F5B"), Color(hex: "6FCB8E"))
    static let warning = Color.dyn(Color(hex: "C28A1E"), Color(hex: "E6BB55"))
    static let danger = Color.dyn(Color(hex: "BF463B"), Color(hex: "E78279"))

    // MARK: Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    // Common radii / spacing
    static let cornerLarge: CGFloat = 20
    static let cornerMedium: CGFloat = 14
    static let cornerSmall: CGFloat = 9

    /// Deterministic two-color gradient seeded by an integer hue (0...359).
    static func coverGradient(hue: Int) -> LinearGradient {
        let h = Double((hue % 360 + 360) % 360) / 360.0
        let c1 = Color(hue: h, saturation: 0.55, brightness: 0.78)
        let c2 = Color(hue: (h + 0.08).truncatingRemainder(dividingBy: 1.0),
                       saturation: 0.68, brightness: 0.55)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Deterministic solid color seeded by an integer hue, for player chips.
    static func playerColor(hue: Int) -> Color {
        let h = Double((hue % 360 + 360) % 360) / 360.0
        return Color(hue: h, saturation: 0.6, brightness: 0.72)
    }
}
