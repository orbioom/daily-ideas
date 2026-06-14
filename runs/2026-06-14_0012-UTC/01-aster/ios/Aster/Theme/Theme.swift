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

/// Central design tokens for Aster. Every color/font referenced in a view is defined here.
enum Theme {
    // Surfaces
    static let bg         = Color.dyn(0xF7F7FB, 0x121218)
    static let surface    = Color.dyn(0xFFFFFF, 0x1C1C24)
    static let surfaceAlt = Color.dyn(0xEFEFF5, 0x24242E)

    // Ink (text)
    static let ink     = Color.dyn(0x1B1B22, 0xF3F3F8)
    static let inkSoft = Color.dyn(0x55555F, 0xB4B4C0)
    static let inkFaint = Color.dyn(0x8A8A96, 0x76767F)

    // Accent (indigo)
    static let accent     = Color.dyn(0x5A5CD6, 0x8C8DF0)
    static let accentSoft = Color.dyn(0xE6E6FB, 0x2C2C46)

    // Lines & status
    static let hairline = Color.dyn(0xE2E2EC, 0x32323E)
    static let good     = Color.dyn(0x2F9E6B, 0x57C998)
    static let bad      = Color.dyn(0xC2453B, 0xF08278)

    // Canvas backdrop (slightly distinct from app bg for depth)
    static let canvasBg = Color.dyn(0xF1F1F8, 0x0E0E14)

    // MARK: - Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    // Common metrics
    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 10
}
