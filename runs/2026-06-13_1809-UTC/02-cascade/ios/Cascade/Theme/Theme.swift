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

/// Cascade — a calm fintech identity: paper-white, forest greens, a debt-free flag.
enum Theme {
    static let bg         = Color.dyn(0xF1F5F1, 0x0C1411)
    static let surface    = Color.dyn(0xFFFFFF, 0x14201B)
    static let surfaceAlt = Color.dyn(0xE7EEE7, 0x1B2A23)
    static let ink        = Color.dyn(0x16241D, 0xEAF3EC)
    static let inkSoft    = Color.dyn(0x4C5E54, 0xA6BBAE)
    static let inkFaint   = Color.dyn(0x86988C, 0x6C8276)
    static let accent     = Color.dyn(0x1C9A5E, 0x37BE7C)   // forest / mint
    static let accentSoft = Color.dyn(0xBEE6CF, 0x214A35)
    static let good       = Color.dyn(0x1C9A5E, 0x37BE7C)
    static let bad        = Color.dyn(0xC0492F, 0xE67D63)
    static let warn       = Color.dyn(0xC2871A, 0xE0AC4E)
    static let hairline   = Color.dyn(0xD6E0D7, 0x24362C)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
