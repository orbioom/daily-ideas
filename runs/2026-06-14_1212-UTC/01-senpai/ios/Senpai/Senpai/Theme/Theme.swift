import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

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

/// Senpai's visual identity — a vibrant "streaming / otaku" language built
/// around magenta-pink #E24A8B, dark-mode-first but first-class in light too.
enum Theme {
    static let bg = Color.dyn(0xF7F4FA, 0x0E0B14)           // soft lavender paper / near-black indigo
    static let surface = Color.dyn(0xFFFFFF, 0x1A1424)       // card
    static let surfaceAlt = Color.dyn(0xF0EAF6, 0x241A33)    // alt card
    static let ink = Color.dyn(0x1E1626, 0xF4EEFA)           // primary text
    static let inkSoft = Color.dyn(0x6A5E78, 0xBBAACB)       // secondary text
    static let inkFaint = Color.dyn(0x9A8FA8, 0x7C6E90)      // tertiary text
    static let accent = Color.dyn(0xD9337A, 0xE24A8B)        // magenta-pink (darker in light for AA contrast)
    static let accentSoft = Color.dyn(0xFBE3EF, 0x35192A)    // tinted fill
    static let violet = Color.dyn(0x6B4BD6, 0x9A7DF0)        // secondary accent (otaku neon)
    static let cyan = Color.dyn(0x1E8FA8, 0x4FCBE0)          // tertiary accent
    static let hairline = Color.dyn(0xE6DEEF, 0x2E2440)      // separators
    static let good = Color.dyn(0x2E8C5A, 0x5FD08C)          // positive
    static let bad = Color.dyn(0xC0392B, 0xE0795F)           // negative / destructive
    static let gold = Color.dyn(0xBE8A1E, 0xF0C44C)          // scores / favorites

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func display(_ s: CGFloat, _ w: Font.Weight = .bold) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// Deterministic two-stop gradient for a cover, driven by a hue in 0...1.
    /// Used because the app ships no cover images — every title gets a stable, vivid card.
    static func coverGradient(hue: Double) -> LinearGradient {
        let h = min(max(hue, 0), 1)
        let c1 = Color(hue: h, saturation: 0.62, brightness: 0.82)
        let c2 = Color(hue: (h + 0.12).truncatingRemainder(dividingBy: 1.0),
                       saturation: 0.78, brightness: 0.55)
        return LinearGradient(colors: [c1, c2],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
}
