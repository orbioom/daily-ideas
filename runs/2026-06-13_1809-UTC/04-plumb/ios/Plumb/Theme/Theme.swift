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

/// Plumb — a private-wealth identity: deep navy, warm gold, parchment.
enum Theme {
    static let bg         = Color.dyn(0xF4F1E9, 0x0A0D18)
    static let surface    = Color.dyn(0xFFFFFF, 0x121726)
    static let surfaceAlt = Color.dyn(0xEAE4D5, 0x1A2133)
    static let ink        = Color.dyn(0x1A2238, 0xEFEADB)
    static let inkSoft    = Color.dyn(0x55607A, 0xA9B0C4)
    static let inkFaint   = Color.dyn(0x8A93A8, 0x6C7488)
    static let accent     = Color.dyn(0xB28311, 0xD2A742)   // gold
    static let accentSoft = Color.dyn(0xE7D7A8, 0x3C3320)
    static let good       = Color.dyn(0x1F8A57, 0x44C285)
    static let bad        = Color.dyn(0xBE4530, 0xE07A64)
    static let hairline   = Color.dyn(0xDBD3C0, 0x232B40)

    /// Palette for allocation charts (light/dark pairs).
    static let chartColors: [(UInt, UInt)] = [
        (0xB28311, 0xD2A742), (0x2E6FA8, 0x5B9AD2), (0x1F8A57, 0x44C285),
        (0x8A4FBF, 0xB07FE0), (0xC2683A, 0xE0915F), (0x3FA0A6, 0x67C6CC),
        (0xB23F6E, 0xDC709A), (0x6B7A8F, 0x97A4B6)
    ]
    static func chartColor(_ i: Int) -> Color {
        let c = chartColors[i % chartColors.count]; return .dyn(c.0, c.1)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
