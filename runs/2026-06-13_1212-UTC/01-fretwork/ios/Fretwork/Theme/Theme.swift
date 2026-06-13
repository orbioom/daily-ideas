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

    /// Resolves to `light` in light mode and `dark` in dark mode.
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

/// Fretwork — a luthier's-workbench identity: warm walnut, brass, honey amber.
enum Theme {
    static let bg         = Color.dyn(0xF4EEE6, 0x17120D)
    static let surface    = Color.dyn(0xFFFFFF, 0x231A12)
    static let surfaceAlt  = Color.dyn(0xEDE3D6, 0x2E2218)
    static let ink        = Color.dyn(0x2A2118, 0xF3E9DC)
    static let inkSoft    = Color.dyn(0x6E5E4C, 0xC3B09A)
    static let inkFaint   = Color.dyn(0x9A8870, 0x7E6E5C)
    static let accent     = Color.dyn(0xB5731F, 0xD79B4A)   // honey amber / brass
    static let accentSoft = Color.dyn(0xE7C58A, 0x5A4326)
    static let good       = Color.dyn(0x3E7D57, 0x67BE8C)
    static let bad        = Color.dyn(0xB1442F, 0xE0795F)
    static let hairline   = Color.dyn(0xD9CDBC, 0x3A2C20)
    static let board      = Color.dyn(0x3A2A1C, 0x2A1E12)   // fretboard wood
    static let boardLine  = Color.dyn(0xCBB48F, 0xB79A6E)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
