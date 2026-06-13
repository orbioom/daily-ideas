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

/// Savant — a playful, electric quiz-night identity: violet, lamp-glow gold.
enum Theme {
    static let bg         = Color.dyn(0xF3F1FB, 0x0E0A1A)
    static let surface    = Color.dyn(0xFFFFFF, 0x191333)
    static let surfaceAlt = Color.dyn(0xEAE5F8, 0x231A45)
    static let ink        = Color.dyn(0x1E1733, 0xEEE9FB)
    static let inkSoft    = Color.dyn(0x594F7A, 0xB4ACD0)
    static let inkFaint   = Color.dyn(0x9088B0, 0x756B96)
    static let accent     = Color.dyn(0x6E3CF0, 0x9B79FF)   // violet
    static let accentSoft = Color.dyn(0xDCD0FB, 0x2E2257)
    static let gold       = Color.dyn(0xCB8A12, 0xF0B844)
    static let good       = Color.dyn(0x1F9A60, 0x42C384)
    static let bad        = Color.dyn(0xCB3B53, 0xEC6E83)
    static let hairline   = Color.dyn(0xDDD6F0, 0x2C2350)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
