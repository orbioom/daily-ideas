import SwiftUI

extension Color {
    /// Build a color from a hex literal (0xRRGGBB).
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A color that resolves differently in light vs dark mode.
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

/// Warm, smoky, confident palette — ember orange-red on charcoal.
/// All colors are dynamic so contrast holds in light AND dark mode.
enum Theme {
    static let bg = Color.dyn(0xF7F1EA, 0x121110)          // warm ash / charcoal black
    static let surface = Color.dyn(0xFFFFFF, 0x1E1C1A)      // card
    static let surfaceAlt = Color.dyn(0xF0E7DC, 0x282421)   // alt card / grate
    static let ink = Color.dyn(0x241C16, 0xF4EDE5)          // primary text
    static let inkSoft = Color.dyn(0x6B5C4F, 0xC0B3A6)      // secondary text
    static let inkFaint = Color.dyn(0x9C8B7C, 0x807164)     // tertiary text
    static let accent = Color.dyn(0xD23A1E, 0xF15A33)       // ember orange-red
    static let accentSoft = Color.dyn(0xF8DFD6, 0x3A211A)   // tinted fill
    static let hairline = Color.dyn(0xE3D7C8, 0x342F2A)     // separators
    static let ember = Color.dyn(0xE8861E, 0xF7A23C)        // glowing coals (warm secondary)
    static let good = Color.dyn(0x3C8A4E, 0x5FBE74)         // done / safe
    static let warn = Color.dyn(0xC97A12, 0xE8A23C)         // almost / stall
    static let bad = Color.dyn(0xB23A22, 0xE0795F)          // overcooked / destructive

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Big temperature / timer numerals: rounded, monospaced digits read at a glance.
    static func numeral(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
