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

/// Lope — an energetic, athletic identity. Charcoal + volt lime.
enum Theme {
    static let bg       = Color.dyn(0xF4F5F0, 0x101113)
    static let surface  = Color.dyn(0xFFFFFF, 0x1B1D20)
    static let surfaceAlt = Color.dyn(0xEAEBE4, 0x24272B)
    static let ink      = Color.dyn(0x161719, 0xF3F4EF)
    static let inkSoft  = Color.dyn(0x595B5E, 0xA9ACB0)
    static let inkFaint = Color.dyn(0x8B8E92, 0x6C7074)
    static let accent   = Color.dyn(0x5C8A00, 0xB6F500)   // volt lime (AA-tuned per mode)
    static let accentInk = Color.dyn(0xFFFFFF, 0x101113)   // text on accent
    static let coral    = Color.dyn(0xE0483B, 0xFF6A5C)
    static let hairline = Color.dyn(0xDFE0D9, 0x2C2F33)

    // Segment colors for the run player
    static let runColor    = Color.dyn(0x3C7A00, 0xA6E000)
    static let walkColor   = Color.dyn(0x2E6FB0, 0x5AA9E6)
    static let warmupColor = Color.dyn(0xC07A12, 0xE0A33A)
    static let cooldownColor = Color.dyn(0x3F8F86, 0x55BFB3)

    static func segmentColor(_ kind: SegmentKind) -> Color {
        switch kind {
        case .warmup: return warmupColor
        case .run: return runColor
        case .walk: return walkColor
        case .cooldown: return cooldownColor
        }
    }

    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
