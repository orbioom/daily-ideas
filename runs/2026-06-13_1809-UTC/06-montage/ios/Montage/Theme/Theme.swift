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

/// Montage — a vibrant creator-studio identity: warm pink, clean cards.
enum Theme {
    static let bg         = Color.dyn(0xF7F1F4, 0x120A10)
    static let surface    = Color.dyn(0xFFFFFF, 0x1E141A)
    static let surfaceAlt = Color.dyn(0xF0E5EB, 0x2A1D25)
    static let ink        = Color.dyn(0x231019, 0xF6E9EF)
    static let inkSoft    = Color.dyn(0x6A5560, 0xC0AAB4)
    static let inkFaint   = Color.dyn(0xA08D97, 0x7C6772)
    static let accent     = Color.dyn(0xDB3573, 0xF06A9B)   // pink
    static let accentSoft = Color.dyn(0xF8D2E0, 0x42202F)
    static let good       = Color.dyn(0x2E9A60, 0x46C384)
    static let bad        = Color.dyn(0xC0492F, 0xE67D63)
    static let hairline   = Color.dyn(0xE6D7DE, 0x33232C)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
