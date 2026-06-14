import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Resolves to `l` in light mode and `d` in dark mode.
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

/// Clinical-calm palette built around a crimson/coral accent.
enum Theme {
    static let bg = Color.dyn(0xF7F4F1, 0x121013)          // warm paper / near-black
    static let surface = Color.dyn(0xFFFFFF, 0x1E1B20)      // card
    static let surfaceAlt = Color.dyn(0xF0EBE6, 0x272329)   // alt card
    static let ink = Color.dyn(0x201B22, 0xF4EFEF)          // primary text
    static let inkSoft = Color.dyn(0x6A6068, 0xB7AEB4)      // secondary text
    static let inkFaint = Color.dyn(0x9A9098, 0x7A7178)     // tertiary text
    static let accent = Color.dyn(0xDC4C5A, 0xF06B78)       // crimson / coral
    static let accentSoft = Color.dyn(0xFADEE1, 0x3A2025)   // tinted fill
    static let hairline = Color.dyn(0xE7DFD9, 0x332E35)     // separators

    // Glucose range colors — used everywhere readings appear.
    static let inRange = Color.dyn(0x2E9E5B, 0x57C684)      // green: in target
    static let elevated = Color.dyn(0xCB8A1E, 0xE5AE4D)     // amber: elevated
    static let high = Color.dyn(0xC23B3B, 0xE5736F)         // crimson: high
    static let low = Color.dyn(0x3D6FC7, 0x6E9BEC)          // indigo/blue: low

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}
