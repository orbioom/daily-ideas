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

/// Peregrine visual language: cool, atmospheric teal over quiet near-neutral
/// surfaces. Teal is the rare luminous accent; everything else is calm ink.
enum Theme {
    // Backgrounds & surfaces
    static let bg = Color.dyn(0xF4F7F7, 0x0B1212)
    static let surface = Color.dyn(0xFFFFFF, 0x132020)
    static let surfaceAlt = Color.dyn(0xEAF1F1, 0x1A2A2A)

    // Ink
    static let ink = Color.dyn(0x16201F, 0xF2F6F6)
    static let inkSoft = Color.dyn(0x47565A, 0xAEC2C2)
    static let inkFaint = Color.dyn(0x8497A0, 0x6A8181)

    // Accent (teal)
    static let accent = Color.dyn(0x148282, 0x49C9C9)
    static let accentSoft = Color.dyn(0xD6ECEC, 0x12403F)

    // Lines & semantic
    static let hairline = Color.dyn(0xDDE7E7, 0x24383A)
    static let good = Color.dyn(0x1E8C5A, 0x57D39A)
    static let bad = Color.dyn(0xC0392B, 0xF08379)

    // App-specific continent tints (used by rings / badges)
    static let warm = Color.dyn(0xC97A2B, 0xE6A95C)   // Africa
    static let sky = Color.dyn(0x2E6FB0, 0x6FB3F0)    // Asia
    static let violet = Color.dyn(0x6B4FB0, 0xA98BE8) // Europe

    // MARK: Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
