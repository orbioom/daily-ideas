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

/// Portico — a classical-marble identity: warm stone, oxblood, terracotta.
enum Theme {
    static let bg         = Color.dyn(0xF3EEE4, 0x1B1712)
    static let surface    = Color.dyn(0xFFFFFF, 0x262019)
    static let surfaceAlt  = Color.dyn(0xEAE2D4, 0x322A20)
    static let ink        = Color.dyn(0x2A2017, 0xF0E6D8)
    static let inkSoft    = Color.dyn(0x6E6048, 0xC3B49A)
    static let inkFaint   = Color.dyn(0x9A8C70, 0x7E705A)
    static let accent     = Color.dyn(0xA0432F, 0xCB6B52)   // oxblood / terracotta
    static let accentSoft = Color.dyn(0xE7C9B0, 0x4A2E22)
    static let good       = Color.dyn(0x4F7A5A, 0x6FBE8C)
    static let bad        = Color.dyn(0xB1442F, 0xE0795F)
    static let hairline   = Color.dyn(0xDED3C0, 0x3A3026)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
