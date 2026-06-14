import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Returns a dynamic color that resolves differently in light vs dark mode.
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

/// Crisp, trustworthy fintech-calm design system for Allot.
enum Theme {
    static let bg = Color.dyn(0xF4F6F5, 0x101513)          // neutral paper / near-black
    static let surface = Color.dyn(0xFFFFFF, 0x1A211E)      // card
    static let surfaceAlt = Color.dyn(0xEDF1EF, 0x232C28)   // alt card / fills
    static let ink = Color.dyn(0x14201B, 0xF1F6F3)          // primary text
    static let inkSoft = Color.dyn(0x556059, 0xAFBBB4)      // secondary text
    static let inkFaint = Color.dyn(0x8A958E, 0x6E7A73)     // tertiary text
    static let accent = Color.dyn(0x2E9E7B, 0x46C098)       // teal-green
    static let accentSoft = Color.dyn(0xDDF1EA, 0x1E3A31)   // tinted fill
    static let hairline = Color.dyn(0xE2E8E5, 0x2C3631)     // separators

    static let good = Color.dyn(0x2E9E7B, 0x4FCBA0)         // funded / positive
    static let bad = Color.dyn(0xC53B36, 0xF06B62)          // overspent / negative
    static let warn = Color.dyn(0xBE8A12, 0xE6B43E)         // underfunded / assign me

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// Money figures use a rounded, monospaced-digit feel for tidy columns.
    static func money(_ s: CGFloat, _ w: Font.Weight = .semibold) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// A stable, pleasant color for a chart slice given a 0...1 hue position,
    /// kept in the teal–green–blue family for a calm fintech feel.
    static func slice(hue: Double) -> Color {
        let clamped = min(max(hue, 0), 1)
        // Sweep from teal (0.45) through green/blue, avoiding harsh reds.
        let h = 0.30 + clamped * 0.40
        return Color(hue: h.truncatingRemainder(dividingBy: 1.0), saturation: 0.55, brightness: 0.78)
    }
}
