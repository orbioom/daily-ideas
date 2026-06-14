import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A color that resolves differently in light vs dark mode.
    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Cobble's design language: playful-but-premium, vivid blue accent, glassy blocks,
/// calm gridded board. Light + dark first-class via `Color.dyn`.
enum Theme {
    static let bg = Color.dyn(0xF4F6FB, 0x0E1016)            // app background
    static let surface = Color.dyn(0xFFFFFF, 0x191D27)        // card / panel
    static let surfaceAlt = Color.dyn(0xEDF1F9, 0x222735)     // alt surface
    static let ink = Color.dyn(0x141A26, 0xF2F5FB)            // primary text
    static let inkSoft = Color.dyn(0x55607A, 0xAEB7CC)        // secondary text
    static let inkFaint = Color.dyn(0x9099AE, 0x6B7488)       // tertiary text
    static let accent = Color.dyn(0x4361E8, 0x6E86F2)         // vivid blue accent
    static let accentSoft = Color.dyn(0xE2E8FD, 0x222B47)     // tinted fill
    static let hairline = Color.dyn(0xE1E6F0, 0x2A3040)       // separators
    static let good = Color.dyn(0x2E9E6B, 0x4FCB92)           // valid placement
    static let bad = Color.dyn(0xD64545, 0xEF6B6B)            // invalid / destructive

    /// The calm board grid surface and its cell wells.
    static let boardBG = Color.dyn(0xE7ECF6, 0x141925)
    static let cellEmpty = Color.dyn(0xDCE3F1, 0x1C2230)
    static let cellHairline = Color.dyn(0xCBD5EA, 0x262E40)

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
