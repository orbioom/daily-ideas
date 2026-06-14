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

/// Central design tokens for Abacus. Every color/font token used in a view must
/// be defined here so the app stays cohesive across light and dark modes.
enum Theme {
    // Surfaces
    static let bg         = Color.dyn(0xF5F7F5, 0x0D1311)
    static let surface    = Color.dyn(0xFFFFFF, 0x16201C)
    static let surfaceAlt = Color.dyn(0xEEF2EF, 0x1E2A25)

    // Text
    static let ink     = Color.dyn(0x16201C, 0xF1F5F2)
    static let inkSoft = Color.dyn(0x4A5751, 0xB6C2BC)
    static let inkFaint = Color.dyn(0x8A958F, 0x6E7C76)

    // Accent (deep teal-green)
    static let accent     = Color.dyn(0x1E785F, 0x46C39B)
    static let accentSoft = Color.dyn(0xD8ECE5, 0x143027)

    // Lines & semantic
    static let hairline = Color.dyn(0xE2E8E4, 0x26332D)
    static let good     = Color.dyn(0x1E785F, 0x46C39B)
    static let bad      = Color.dyn(0xB23A2E, 0xE8796B)

    // Chart tints — principal vs interest
    static let principalTint = Color.dyn(0x1E785F, 0x46C39B)
    static let interestTint  = Color.dyn(0xCBA24A, 0xE0B85C)
    static let baselineTint  = Color.dyn(0xB23A2E, 0xE8796B)

    // Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
