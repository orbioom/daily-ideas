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

/// Sprig's design language: warm nursery meets clinical clarity. Sage-and-clinical green
/// accent (#3F9D6B), soft cream surfaces, calm gridded charts. Light + dark first-class.
enum Theme {
    static let bg = Color.dyn(0xF6F4EE, 0x0F1311)            // warm cream / deep forest
    static let surface = Color.dyn(0xFFFFFF, 0x18201B)        // card / panel
    static let surfaceAlt = Color.dyn(0xEFEDE4, 0x202A23)     // alt surface
    static let ink = Color.dyn(0x1C261F, 0xF1F5F0)            // primary text
    static let inkSoft = Color.dyn(0x5A6660, 0xA9B6AC)        // secondary text
    static let inkFaint = Color.dyn(0x919C94, 0x6C7970)       // tertiary text
    static let accent = Color.dyn(0x3F9D6B, 0x5EBE8A)         // clinical-nursery green
    static let accentSoft = Color.dyn(0xDDF0E5, 0x1E342A)     // tinted fill
    static let hairline = Color.dyn(0xE4E1D6, 0x29332C)       // separators

    static let good = Color.dyn(0x2E9E6B, 0x4FCB92)           // on track / success
    static let warn = Color.dyn(0xCB8B2E, 0xE8B65A)           // keep an eye / due soon
    static let bad = Color.dyn(0xC8553A, 0xE5795E)            // overdue / destructive

    /// Warm secondary used for sex/child color accents.
    static let blush = Color.dyn(0xE08AA0, 0xE79EB2)
    static let sky = Color.dyn(0x5B91C9, 0x78A8D9)

    /// Percentile-curve band tints for charts.
    static let curveBand = Color.dyn(0xEDE9DD, 0x1B231D)

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
