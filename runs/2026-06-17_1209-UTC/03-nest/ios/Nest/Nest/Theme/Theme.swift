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
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }

    /// Build a Color from a stored "#RRGGBB" hex string; falls back to the app accent on bad input.
    static func fromGoalHex(_ string: String) -> Color {
        var s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt(s, radix: 16) else { return Theme.accent }
        return Color(hex: value)
    }
}

/// Warm, trustworthy "growth" palette built around a green accent.
enum Theme {
    static let bg = Color.dyn(0xF6F4EE, 0x12140F)            // warm paper / deep moss-black
    static let surface = Color.dyn(0xFFFFFF, 0x1E211A)        // card
    static let surfaceAlt = Color.dyn(0xEFEDE3, 0x262A20)     // alt card / inset
    static let ink = Color.dyn(0x1E2419, 0xF1F3EA)           // primary text
    static let inkSoft = Color.dyn(0x5C6452, 0xBAC1AC)        // secondary text
    static let inkFaint = Color.dyn(0x8B927E, 0x767D68)       // tertiary text
    static let accent = Color.dyn(0x2F8F5B, 0x4BBE7E)         // growth green
    static let accentSoft = Color.dyn(0xDDEEE2, 0x223326)     // tinted fill
    static let hairline = Color.dyn(0xE3E0D4, 0x303528)       // separators
    static let good = Color.dyn(0x2F8F5B, 0x5DC98C)           // on track / positive
    static let warn = Color.dyn(0xC9852A, 0xE3A94E)           // behind / caution
    static let bad = Color.dyn(0xBE4A33, 0xE07A63)            // destructive / withdrawal
    static let sky = Color.dyn(0x3A77B5, 0x6AA7E0)            // ahead / informational

    /// A palette of pleasing goal accent colors (hex strings) the user can choose from.
    static let goalSwatches: [String] = [
        "#2F8F5B", "#3A77B5", "#9B5DE5", "#E06C4F",
        "#C9852A", "#1FA8A0", "#D4567E", "#5C6452"
    ]

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Tabular monospaced figures for money.
    static func money(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}
