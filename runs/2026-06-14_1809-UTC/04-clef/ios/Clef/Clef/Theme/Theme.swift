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

/// Elegant, musical palette. Parchment-ink feel with an indigo/violet accent.
enum Theme {
    static let bg = Color.dyn(0xF7F3EC, 0x121019)           // warm off-white / deep ink
    static let surface = Color.dyn(0xFFFFFF, 0x1E1B29)       // card
    static let surfaceAlt = Color.dyn(0xEFE9DF, 0x272336)    // alt card
    static let ink = Color.dyn(0x231F2E, 0xF2EEF8)           // primary text
    static let inkSoft = Color.dyn(0x5C5670, 0xB6AECB)       // secondary text
    static let inkFaint = Color.dyn(0x938CA6, 0x7A7393)      // tertiary text
    static let accent = Color.dyn(0x6A5BD0, 0x8E80E8)        // indigo / violet
    static let accentSoft = Color.dyn(0xE7E2F8, 0x2C2742)    // tinted fill
    static let hairline = Color.dyn(0xE2DBCE, 0x322D44)      // separators
    static let good = Color.dyn(0x2E8B57, 0x5FC98C)          // correct
    static let bad = Color.dyn(0xC0413A, 0xE57A6E)           // wrong / destructive
    static let staff = Color.dyn(0x3A3450, 0xC8C0E0)         // staff lines & note heads (legible both modes)

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}
