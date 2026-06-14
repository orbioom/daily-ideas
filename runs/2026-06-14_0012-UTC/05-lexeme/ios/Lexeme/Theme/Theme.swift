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

/// Lexeme's scholarly identity: warm cream/paper surfaces in light mode,
/// deep ink in dark mode, an ink-blue accent, and a serif voice for words.
enum Theme {
    // Backgrounds & surfaces
    static let bg         = Color.dyn(0xF7F4EC, 0x12141E)   // paper / deep ink
    static let surface    = Color.dyn(0xFFFDF7, 0x1B1E2B)   // card
    static let surfaceAlt = Color.dyn(0xF0EBDD, 0x232739)   // recessed / chips

    // Text
    static let ink      = Color.dyn(0x231F1A, 0xF2EFE7)     // primary
    static let inkSoft  = Color.dyn(0x5A5248, 0xB7B2C4)     // secondary
    static let inkFaint = Color.dyn(0x8C8377, 0x6E6B82)     // tertiary

    // Accent (ink blue)
    static let accent     = Color.dyn(0x3C50A5, 0x8090E0)
    static let accentSoft = Color.dyn(0xE2E5F4, 0x2A3052)

    // Lines & semantic
    static let hairline = Color.dyn(0xE0D9C8, 0x2E3245)
    static let good     = Color.dyn(0x2E7D5B, 0x6FD3A4)     // correct
    static let bad      = Color.dyn(0xB04434, 0xE8927E)     // wrong

    // App-specific tints (tier badges)
    static let gold   = Color.dyn(0x9A7A1E, 0xD9BC6B)       // GRE
    static let teal   = Color.dyn(0x2A6E78, 0x77C9D4)       // SAT

    // MARK: Fonts
    /// Serif voice — used for headings and the vocabulary words themselves.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Rounded voice — used for UI chrome, numbers, controls.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
