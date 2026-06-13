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

/// Lexicon — a crisp word-game identity: indigo chrome, classic tile colors.
enum Theme {
    static let bg        = Color.dyn(0xF5F5F8, 0x12121C)
    static let surface   = Color.dyn(0xFFFFFF, 0x1D1D2A)
    static let surfaceAlt = Color.dyn(0xE9E9F0, 0x282838)
    static let ink       = Color.dyn(0x1A1A24, 0xF2F2F6)
    static let inkSoft   = Color.dyn(0x55556A, 0xA8A8BC)
    static let inkFaint  = Color.dyn(0x8A8AA0, 0x6A6A80)
    static let accent    = Color.dyn(0x4F7A45, 0x6AAA64)   // green chrome
    static let hairline  = Color.dyn(0xDADAE4, 0x30303F)

    /// High-contrast (color-blind) palette toggle, mirrored from settings.
    static var colorBlind = UserDefaults.standard.bool(forKey: "colorBlind")

    // Tile / key states (color-blind uses blue/orange instead of green/amber)
    static var correct: Color { colorBlind ? Color.dyn(0x1273D4, 0x3A92E0) : Color.dyn(0x6AAA64, 0x6AAA64) }
    static var present: Color { colorBlind ? Color.dyn(0xE2820A, 0xE89A33) : Color.dyn(0xC9A227, 0xC9B458) }
    static let absent    = Color.dyn(0x787C8E, 0x3A3A4C)
    static let tileEmpty = Color.dyn(0xFFFFFF, 0x1D1D2A)
    static let tileBorder = Color.dyn(0xCBCBD8, 0x3A3A4C)
    static let tileFilledBorder = Color.dyn(0x9A9AB0, 0x55556A)
    static let keyBase   = Color.dyn(0xD3D6DE, 0x53536A)

    static func stateColor(_ s: LetterState) -> Color {
        switch s {
        case .correct: return correct
        case .present: return present
        case .absent: return absent
        case .empty, .filled: return tileEmpty
        }
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
