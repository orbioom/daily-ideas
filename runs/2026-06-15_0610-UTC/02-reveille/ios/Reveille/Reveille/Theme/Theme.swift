import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A color that resolves differently in light vs dark mode.
    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Reveille's design language: calm, warm, dawn-to-dusk. Coral accent (#FF6B5E),
/// soft skies, generous rounded type. Light + dark first-class via `Color.dyn`.
enum Theme {
    static let bg = Color.dyn(0xFBF5F1, 0x0F1117)            // app background (warm paper / deep night)
    static let surface = Color.dyn(0xFFFFFF, 0x1A1D27)        // card / panel
    static let surfaceAlt = Color.dyn(0xF4EAE2, 0x232735)     // alt surface
    static let ink = Color.dyn(0x231A18, 0xF4EFEA)           // primary text
    static let inkSoft = Color.dyn(0x6E5F58, 0xB4ABC4)       // secondary text
    static let inkFaint = Color.dyn(0xA3938B, 0x6E7488)      // tertiary text
    static let accent = Color.dyn(0xFF6B5E, 0xFF8275)        // coral accent
    static let accentSoft = Color.dyn(0xFFE3DE, 0x33222A)    // tinted fill
    static let hairline = Color.dyn(0xEADFD7, 0x2A2E3C)      // separators
    static let good = Color.dyn(0x2E9E78, 0x5BD3A6)          // success
    static let warn = Color.dyn(0xE0913A, 0xF0B45F)          // warning
    static let bad = Color.dyn(0xD64545, 0xEF6B6B)           // destructive

    // Dawn / dusk gradient stops — used on the ring screen and bedside clock.
    static let dawnTop = Color.dyn(0xFFB48A, 0x2A2540)
    static let dawnBottom = Color.dyn(0xFF7E6E, 0x141526)
    static let duskTop = Color.dyn(0x6A5C9E, 0x161826)
    static let duskBottom = Color.dyn(0x2E2A4A, 0x0A0B12)

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
