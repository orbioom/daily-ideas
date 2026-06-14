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

enum Theme {
    // Brand
    static let accent = Color(hex: 0x7A5CF0)         // electric violet
    static let accentSoft = Color.dyn(0xEDE9FE, 0x2A2150)
    static let accentDeep = Color.dyn(0x5B3FD6, 0x9B86FF)

    // Surfaces
    static let bg = Color.dyn(0xF6F5FB, 0x0E0B1A)
    static let surface = Color.dyn(0xFFFFFF, 0x171327)
    static let surfaceRaised = Color.dyn(0xFFFFFF, 0x1F1936)
    static let stroke = Color.dyn(0xE6E3F0, 0x2C2542)

    // Text
    static let text = Color.dyn(0x161222, 0xF2EFFA)
    static let textSecondary = Color.dyn(0x5B5670, 0xACA5C4)
    static let textFaint = Color.dyn(0x8A85A0, 0x7B7498)

    // Status / signal colors (AA-tested for both modes on surfaces)
    static let success = Color.dyn(0x1B873F, 0x4ADE80)
    static let warning = Color.dyn(0xB45309, 0xFBBF24)
    static let danger = Color.dyn(0xC02626, 0xFB7185)
    static let info = Color.dyn(0x2563EB, 0x60A5FA)

    // Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Common metrics
    static let corner: CGFloat = 18
    static let cardCorner: CGFloat = 16
}
