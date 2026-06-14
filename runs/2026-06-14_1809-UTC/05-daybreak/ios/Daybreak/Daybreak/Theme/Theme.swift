import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Light/dark dynamic color from two hex values.
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

/// Warm sunrise palette. Gold/amber accent over soft dawn (light) / dusk-indigo (dark).
enum Theme {
    static let bg = Color.dyn(0xFCF6EC, 0x12121C)           // warm paper / deep indigo night
    static let surface = Color.dyn(0xFFFFFF, 0x1E1E2C)       // card
    static let surfaceAlt = Color.dyn(0xF6EBDA, 0x262636)    // alt card
    static let ink = Color.dyn(0x2A2016, 0xF3EEE6)           // primary text
    static let inkSoft = Color.dyn(0x6B5C4C, 0xB7AEC4)       // secondary text
    static let inkFaint = Color.dyn(0x9C8B78, 0x756C84)      // tertiary text
    // LIGHT accent is the deeper 0xC77E22 so white text keeps >=3:1 contrast.
    static let accent = Color.dyn(0xC77E22, 0xE8A33D)        // gold / amber
    // Text/glyph color to place ON the accent: white in light (3.26:1 on C77E22),
    // near-black in dark (8.6:1 on E8A33D) — both clear AA.
    static let onAccent = Color.dyn(0xFFFFFF, 0x1A1206)
    // Text/glyph to place ON the soft dawn/dusk header gradients: deep brown over the
    // light peach gradient (>=7.8:1), white over the dark plum gradient (>=11:1).
    static let onHeader = Color.dyn(0x3A2A12, 0xFFFFFF)
    static let accentSoft = Color.dyn(0xFBEACF, 0x39301F)    // tinted fill
    static let hairline = Color.dyn(0xEADcC7, 0x33334A)      // separators
    static let good = Color.dyn(0x3E8E5A, 0x67C28A)          // positive
    static let bad = Color.dyn(0xC0492F, 0xE0795F)           // negative / destructive

    /// Soft dawn gradient for headers (peach -> gold). Decorative only.
    static var dawnGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dyn(0xFCE3C4, 0x2A2440), Color.dyn(0xF6C98A, 0x3A2E52)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
}
