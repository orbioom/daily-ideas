import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0, opacity: 1.0)
    }
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255.0,
                           green: CGFloat((h >> 8) & 0xFF) / 255.0,
                           blue: CGFloat(h & 0xFF) / 255.0, alpha: 1.0)
        })
    }
}

/// Epigraph — a literary, letterpress identity. Ivory, ink, brass.
enum Theme {
    static let bg       = Color.dyn(0xF6F1E7, 0x15120D)
    static let surface  = Color.dyn(0xFFFDF6, 0x201C15)
    static let surfaceAlt = Color.dyn(0xEDE6D5, 0x2A251C)
    static let ink      = Color.dyn(0x211C13, 0xF2ECDD)
    static let inkSoft  = Color.dyn(0x5E5642, 0xB3AB97)
    static let inkFaint = Color.dyn(0x8C846D, 0x756D5B)
    static let accent   = Color.dyn(0xA9792C, 0xD2A24E)   // brass
    static let accentSoft = Color.dyn(0xEFE3CB, 0x33291A)
    static let hairline = Color.dyn(0xDED5C0, 0x322C21)

    static let spineColors: [(UInt, UInt)] = [
        (0x7C3B2E, 0xB6604F), (0x2F5D50, 0x57907F), (0x3C4E72, 0x7488AE),
        (0x6E4A78, 0xA77EB0), (0xA9792C, 0xD2A24E), (0x8A5320, 0xC58A4A),
        (0x4A6072, 0x7E97AA), (0x6B6B2E, 0xAEAE57)
    ]
    static func spine(_ i: Int) -> Color {
        let c = spineColors[((i % spineColors.count) + spineColors.count) % spineColors.count]
        return .dyn(c.0, c.1)
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
