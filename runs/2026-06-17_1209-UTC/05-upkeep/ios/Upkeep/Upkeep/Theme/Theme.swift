import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A dynamic color that adapts to light/dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { trait in
            let h = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Calm, dependable "home" palette built around a teal-slate accent.
enum Theme {
    static let bg = Color.dyn(0xF3F6F6, 0x0E1414)          // soft paper / deep slate
    static let surface = Color.dyn(0xFFFFFF, 0x18211F)      // card
    static let surfaceAlt = Color.dyn(0xEAF0EF, 0x1F2A28)   // alt card / inset
    static let ink = Color.dyn(0x16201F, 0xEAF1EF)          // primary text
    static let inkSoft = Color.dyn(0x53625F, 0xA9BAB6)      // secondary text
    static let inkFaint = Color.dyn(0x859591, 0x70817D)     // tertiary text
    static let accent = Color.dyn(0x2C7A78, 0x4FB3AF)       // teal-slate
    static let accentSoft = Color.dyn(0xDCEBEA, 0x1E332F)   // tinted fill
    static let hairline = Color.dyn(0xDEE6E4, 0x283431)     // separators
    static let good = Color.dyn(0x2E8B57, 0x5CC98C)         // fresh / on-time
    static let warn = Color.dyn(0xC9852A, 0xE3A94E)         // due soon
    static let bad = Color.dyn(0xC04A36, 0xE07A66)          // overdue / destructive

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
