import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0,
                  opacity: 1.0)
    }

    /// Resolves to `light` in light mode and `dark` in dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255.0,
                           green: CGFloat((h >> 8) & 0xFF) / 255.0,
                           blue: CGFloat(h & 0xFF) / 255.0,
                           alpha: 1.0)
        })
    }
}

/// Hive — a honeycomb identity: honey gold on near-black or cream.
///
/// The single `accent` is read through a high-contrast switch so the
/// color-blind / high-contrast Settings toggle can swap the gold for a strong
/// blue everywhere at once (the flag lives in `UserDefaults`, mirroring how the
/// left-handed flag is read inside the chord diagram in the sibling apps).
enum Theme {
    static let bg         = Color.dyn(0xF6F1E2, 0x14120A)
    static let surface    = Color.dyn(0xFFFFFF, 0x201C12)
    static let surfaceAlt  = Color.dyn(0xECE4CE, 0x2C2718)
    static let ink        = Color.dyn(0x201B0E, 0xF4ECD8)
    static let inkSoft    = Color.dyn(0x6B6248, 0xBEB48E)
    static let inkFaint   = Color.dyn(0x9A9070, 0x7C745A)
    static let accentSoft = Color.dyn(0xF3E2A0, 0x4A3C12)
    static let hexOuter   = Color.dyn(0xEDE6D2, 0x2E2A1C)
    static let good       = Color.dyn(0x3E8E57, 0x63C083)
    static let bad        = Color.dyn(0xC0392B, 0xE0705F)
    static let hairline   = Color.dyn(0xDED5BC, 0x342E1E)

    /// Honey gold by default; a strong, AA-contrast blue in high-contrast mode.
    static var accent: Color {
        UserDefaults.standard.bool(forKey: "highContrast")
            ? Color.dyn(0x0B5FB0, 0x5AB0FF)
            : Color.dyn(0xE0A400, 0xF2B705)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
