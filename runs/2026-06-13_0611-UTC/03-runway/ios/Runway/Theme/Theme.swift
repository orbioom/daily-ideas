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

/// Runway — a calm, trustworthy fintech identity. Navy + a confident green.
enum Theme {
    static let bg        = Color.dyn(0xF1F4F8, 0x0A1624)
    static let surface   = Color.dyn(0xFFFFFF, 0x122438)
    static let surfaceAlt = Color.dyn(0xE9EEF4, 0x1A3047)
    static let ink       = Color.dyn(0x0E1B2A, 0xEAF1F8)
    static let inkSoft   = Color.dyn(0x4E6173, 0x9DB0C2)
    static let inkFaint  = Color.dyn(0x8295A6, 0x65798C)
    static let accent    = Color.dyn(0x1E9E63, 0x39C77F)   // green
    static let hairline  = Color.dyn(0xDCE3EB, 0x223A52)

    static let safe    = Color.dyn(0x1E9E63, 0x39C77F)
    static let caution = Color.dyn(0xC9842A, 0xE0A33A)
    static let danger  = Color.dyn(0xD0402F, 0xF06A5C)

    static func status(forBalance balance: Double, buffer: Double) -> Color {
        if balance < 0 { return danger }
        if balance < buffer { return caution }
        return safe
    }

    static func num(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
