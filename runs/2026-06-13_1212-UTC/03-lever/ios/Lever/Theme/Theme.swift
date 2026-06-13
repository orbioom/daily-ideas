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

/// Lever — a gritty training-floor identity: concrete, chalk, vivid orange.
enum Theme {
    static let bg         = Color.dyn(0xF1F2F4, 0x111317)
    static let surface    = Color.dyn(0xFFFFFF, 0x1C2027)
    static let surfaceAlt  = Color.dyn(0xE6E8EC, 0x262B33)
    static let ink        = Color.dyn(0x171A1F, 0xEEF1F5)
    static let inkSoft    = Color.dyn(0x5A626D, 0xA6AEB9)
    static let inkFaint   = Color.dyn(0x8C939E, 0x6C737E)
    static let accent     = Color.dyn(0xE8531F, 0xF26B3C)   // vivid orange
    static let accentSoft = Color.dyn(0xF8D2C0, 0x402015)
    static let good       = Color.dyn(0x2E8B57, 0x4FC07F)
    static let bad        = Color.dyn(0xC0392B, 0xE0705F)
    static let hairline   = Color.dyn(0xD9DCE1, 0x2E333B)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
