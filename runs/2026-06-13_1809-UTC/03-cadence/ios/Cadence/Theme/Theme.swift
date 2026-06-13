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

/// Cadence — a calm clinical identity: soft mint paper, teal, healthy greens.
enum Theme {
    static let bg         = Color.dyn(0xEFF6F5, 0x0A1416)
    static let surface    = Color.dyn(0xFFFFFF, 0x12201F)
    static let surfaceAlt = Color.dyn(0xE2EFEC, 0x18302C)
    static let ink        = Color.dyn(0x12211F, 0xE8F3F0)
    static let inkSoft    = Color.dyn(0x4A5E5A, 0xA2B8B3)
    static let inkFaint   = Color.dyn(0x86998F, 0x6A807B)
    static let accent     = Color.dyn(0x12968E, 0x36BDB2)   // teal
    static let accentSoft = Color.dyn(0xBEE6E1, 0x1C463F)
    static let good       = Color.dyn(0x1C9A5E, 0x3DC07E)
    static let bad        = Color.dyn(0xC0492F, 0xE67D63)
    static let warn       = Color.dyn(0xC2871A, 0xE0AC4E)
    static let hairline   = Color.dyn(0xD2E2DE, 0x1F3833)

    /// Per-medication identity colors (light/dark pairs).
    static let pillColors: [(name: String, light: UInt, dark: UInt)] = [
        ("Teal", 0x12968E, 0x36BDB2),
        ("Coral", 0xE06B4E, 0xF0876B),
        ("Indigo", 0x4F5BD5, 0x7C86E8),
        ("Amber", 0xD79A2B, 0xEBB84F),
        ("Rose", 0xD24E78, 0xEC7AA0),
        ("Sky", 0x2E8BC9, 0x5BB0E6),
        ("Plum", 0x8A4FBF, 0xB07FE0),
        ("Moss", 0x5C8F3A, 0x83B860)
    ]

    static func pillColor(_ hex: UInt) -> Color {
        if let m = pillColors.first(where: { $0.light == hex }) { return .dyn(m.light, m.dark) }
        return .dyn(hex, hex)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
