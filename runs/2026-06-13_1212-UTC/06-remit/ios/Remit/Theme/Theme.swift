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

/// Remit — a calm ledger identity: money green over cool slate.
enum Theme {
    static let bg         = Color.dyn(0xF0F3F1, 0x0F1614)
    static let surface    = Color.dyn(0xFFFFFF, 0x18211E)
    static let surfaceAlt  = Color.dyn(0xE5EAE7, 0x222D29)
    static let ink        = Color.dyn(0x16201C, 0xE8F0EC)
    static let inkSoft    = Color.dyn(0x586862, 0xA4B4AE)
    static let inkFaint   = Color.dyn(0x86968F, 0x66766F)
    static let accent     = Color.dyn(0x2F9E76, 0x49C091)   // money green
    static let accentSoft = Color.dyn(0xC4E8D8, 0x1E3A30)
    static let good       = Color.dyn(0x2F9E76, 0x49C091)
    static let bad        = Color.dyn(0xC0392B, 0xE0705F)
    static let warn       = Color.dyn(0xC98A1E, 0xE0A93F)
    static let hairline   = Color.dyn(0xD7DEDB, 0x2A3531)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
