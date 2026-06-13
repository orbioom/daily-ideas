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

/// Verbatim — a scholarly identity: cream paper, indigo ink, serif passages.
enum Theme {
    static let bg         = Color.dyn(0xF4F1E8, 0x14161F)
    static let surface    = Color.dyn(0xFFFFFF, 0x1E2230)
    static let surfaceAlt  = Color.dyn(0xEAE6D8, 0x282D3D)
    static let ink        = Color.dyn(0x20242E, 0xEDEFF5)
    static let inkSoft    = Color.dyn(0x5C6270, 0xACB2C2)
    static let inkFaint   = Color.dyn(0x8A909E, 0x6A7080)
    static let accent     = Color.dyn(0x4453C0, 0x8390EC)   // indigo ink
    static let accentSoft = Color.dyn(0xCDD2F2, 0x2A3060)
    static let good       = Color.dyn(0x3E7D57, 0x63BE8C)
    static let bad        = Color.dyn(0xB1442F, 0xE0795F)
    static let hairline   = Color.dyn(0xDED9C9, 0x30354A)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
