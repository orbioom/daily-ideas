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

/// Core semantic palette for Cusp. Calm sunset-coral identity, native-first,
/// first-class light & dark via `Color.dyn`.
enum Theme {
    // Surfaces
    static let bg          = Color.dyn(0xF7F4F1, 0x141216)
    static let surface     = Color.dyn(0xFFFFFF, 0x1E1B21)
    static let surfaceAlt  = Color.dyn(0xF1ECE7, 0x26222B)

    // Ink (text)
    static let ink         = Color.dyn(0x231F26, 0xF4F1EE)
    static let inkSoft     = Color.dyn(0x6A6470, 0xB6AFBC)
    static let inkFaint    = Color.dyn(0x9C95A2, 0x756E7C)

    // Accent — sunset coral
    static let accent      = Color.dyn(0xE06A45, 0xF58E6A)
    static let accentSoft  = Color.dyn(0xF6D9CE, 0x3A2A26)

    // Lines & status
    static let hairline    = Color.dyn(0xE6DED7, 0x322D38)
    static let good        = Color.dyn(0x2E9E73, 0x57D6A4)
    static let bad         = Color.dyn(0xC2462F, 0xF08A72)

    // A rare luminous green accent reserved for "today" moments.
    static let glow        = Color.dyn(0x2E9E73, 0x5BE0A8)

    // MARK: Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
