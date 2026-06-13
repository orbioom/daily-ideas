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

/// Lumen — a darkroom-studio identity: graphite panels, coral accent.
enum Theme {
    static let bg         = Color.dyn(0xF2F0EE, 0x0C0C0E)
    static let surface    = Color.dyn(0xFFFFFF, 0x18181C)
    static let surfaceAlt = Color.dyn(0xE7E4E1, 0x222227)
    static let canvas     = Color.dyn(0x1C1C20, 0x000000)   // photo backdrop
    static let ink        = Color.dyn(0x1A1A1E, 0xF3F0ED)
    static let inkSoft    = Color.dyn(0x5C5A58, 0xAEACAA)
    static let inkFaint   = Color.dyn(0x95928F, 0x6E6C6A)
    static let accent     = Color.dyn(0xE05432, 0xF07A57)   // coral
    static let accentSoft = Color.dyn(0xF6D6CB, 0x3A241D)
    static let good       = Color.dyn(0x2E9A60, 0x46C384)
    static let bad        = Color.dyn(0xC0492F, 0xE67D63)
    static let hairline   = Color.dyn(0xDCD8D4, 0x2A2A30)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
