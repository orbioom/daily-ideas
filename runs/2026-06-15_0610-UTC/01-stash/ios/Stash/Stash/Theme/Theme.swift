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

    /// Parse a `#RRGGBB` (or `RRGGBB`) string into a Color. Falls back to the
    /// supplied default when the string isn't a valid hex triplet.
    init(hexString: String, fallback: Color = .gray) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt(s, radix: 16) else {
            self = fallback
            return
        }
        self.init(hex: value)
    }

    /// Relative luminance (WCAG-ish) used to pick readable foreground text on a swatch.
    var estimatedLuminance: Double {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
    }

    /// Black or white, whichever reads better on top of this color.
    var readableForeground: Color {
        estimatedLuminance > 0.6 ? Color(hex: 0x16202A) : .white
    }
}

/// Stash's design language: calm, organized, privacy-first wallet. Teal accent,
/// soft card surfaces, generous corners. Light + dark first-class via `Color.dyn`.
enum Theme {
    static let bg = Color.dyn(0xF3F6F6, 0x0C1413)            // app background
    static let surface = Color.dyn(0xFFFFFF, 0x16201F)        // card / panel
    static let surfaceAlt = Color.dyn(0xEAF0EF, 0x1E2A28)     // alt surface
    static let ink = Color.dyn(0x111B1A, 0xF1F6F5)            // primary text
    static let inkSoft = Color.dyn(0x4F605E, 0xA8B7B4)        // secondary text
    static let inkFaint = Color.dyn(0x859390, 0x6A7A77)       // tertiary text
    static let accent = Color.dyn(0x128F8A, 0x35BDB6)         // teal accent
    static let accentSoft = Color.dyn(0xDCEFED, 0x163331)     // tinted fill
    static let hairline = Color.dyn(0xE0E8E6, 0x283533)       // separators
    static let good = Color.dyn(0x2E9E6B, 0x4FCB92)           // positive / success
    static let warn = Color.dyn(0xC8861B, 0xE0A23A)           // caution / expiring
    static let bad = Color.dyn(0xD64545, 0xEF6B6B)            // destructive / depleted

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
