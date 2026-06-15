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

    /// Hex string ("#RRGGBB" or "RRGGBB") → Color, with a safe fallback.
    init(hexString: String, fallback: Color = .gray) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt(s, radix: 16) else {
            self = fallback
            return
        }
        self.init(hex: v)
    }
}

/// Span's design language: a contemplative "midnight & amber" memento-mori calendar.
/// Deep night backgrounds, warm amber accent, calm hairlines. Light + dark first-class.
enum Theme {
    static let bg = Color.dyn(0xF6F4EF, 0x0B0D14)            // app background
    static let surface = Color.dyn(0xFFFFFF, 0x141824)       // card / panel
    static let surfaceAlt = Color.dyn(0xEFEBE2, 0x1C2130)    // alt surface
    static let ink = Color.dyn(0x1A1B22, 0xF3F1EA)           // primary text
    static let inkSoft = Color.dyn(0x5C5E6B, 0xAAB0C2)       // secondary text
    static let inkFaint = Color.dyn(0x9A9CA8, 0x6A7184)      // tertiary text
    static let accent = Color.dyn(0xC78A2E, 0xE8A84B)        // warm amber accent
    static let accentSoft = Color.dyn(0xF6E9D0, 0x2A2519)    // tinted fill
    static let hairline = Color.dyn(0xE3DFD5, 0x232838)      // separators
    static let good = Color.dyn(0x2E9E6B, 0x4FCB92)          // success
    static let bad = Color.dyn(0xC0453B, 0xEF6B6B)           // destructive

    /// Week-dot grid surface tones.
    static let dotPast = Color.dyn(0x5C5E6B, 0xC9CDDA)       // weeks lived (no chapter)
    static let dotFuture = Color.dyn(0xD8D3C8, 0x262C3D)     // weeks ahead
    static let dotFutureRing = Color.dyn(0xCBC5B6, 0x303749) // future dot ring (outline style)

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
