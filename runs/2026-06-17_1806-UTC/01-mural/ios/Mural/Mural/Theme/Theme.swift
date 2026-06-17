import SwiftUI

extension Color {
    /// Initialize an opaque color from a 0xRRGGBB hex value.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A dynamic color that resolves differently for light and dark interface styles.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Central design language for Mural — a premium creative-studio aesthetic.
enum Theme {
    // Brand accent — MUST match AccentColor in Assets (0x7C5CFF violet).
    static let accent = Color(hex: 0x7C5CFF)
    static let accentSoft = Color(hex: 0xA690FF)

    // Surfaces
    static let bg = Color.dyn(0xF1EEFB, 0x0B0A18)
    static let surface = Color.dyn(0xFFFFFF, 0x16142A)
    static let surfaceRaised = Color.dyn(0xF7F4FE, 0x1F1C3A)
    static let hairline = Color.dyn(0xE3DCF7, 0x2B2750)

    // Text / ink
    static let ink = Color.dyn(0x1B1733, 0xF3F0FF)
    static let inkSoft = Color.dyn(0x5C5577, 0xB6AEDC)
    static let inkFaint = Color.dyn(0x8B83A8, 0x7E769F)

    // Semantic
    static let good = Color.dyn(0x1F9D63, 0x4FE0A0)
    static let warn = Color.dyn(0xC77800, 0xFFB84D)
    static let bad = Color.dyn(0xC2334D, 0xFF6B86)

    // Gradients used for hero surfaces and chrome.
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x7C5CFF), Color(hex: 0x4A2FD6), Color(hex: 0xB453FF)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var subtleCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x7C5CFF).opacity(0.16), Color(hex: 0xB453FF).opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Corner radii
    static let radius: CGFloat = 18
    static let radiusSmall: CGFloat = 12
    static let radiusLarge: CGFloat = 28

    // Rounded design font helper.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
