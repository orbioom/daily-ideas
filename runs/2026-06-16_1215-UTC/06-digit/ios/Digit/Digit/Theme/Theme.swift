import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A dynamic color that resolves differently for light and dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Digit's visual identity: warm, friendly, rounded — a clean math playground.
enum Theme {
    /// MUST equal the AccentColor asset (0xF4823C — warm tangerine).
    static let accent = Color(hex: 0xF4823C)
    static let accentDeep = Color.dyn(0xD96A24, 0xFF9C57)

    static let bg = Color.dyn(0xFFF8F2, 0x15110D)
    static let surface = Color.dyn(0xFFFFFF, 0x231C15)
    static let surfaceAlt = Color.dyn(0xFCEFE3, 0x2E251B)
    static let ink = Color.dyn(0x2A2118, 0xFBF4EC)
    static let inkSoft = Color.dyn(0x7A6B5B, 0xB7A793)
    static let hairline = Color.dyn(0xEADBCB, 0x3A2F23)

    static let good = Color.dyn(0x2E9E5B, 0x5FD68C)
    static let warn = Color.dyn(0xE0962A, 0xFFC061)
    static let bad = Color.dyn(0xD0533F, 0xFF8A72)

    // Per-operation accent palette (used across grids, chips, charts).
    static let opAdd = Color.dyn(0x3D8BFD, 0x6FA8FF)
    static let opSub = Color.dyn(0x9B59D0, 0xC18BF0)
    static let opMul = Color.dyn(0xF4823C, 0xFF9C57)
    static let opDiv = Color.dyn(0x2E9E5B, 0x5FD68C)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xF4823C), Color(hex: 0xF6A94B)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let starGold = Color(hex: 0xFFC83D)

    // Corner radii
    static let rSmall: CGFloat = 12
    static let rMedium: CGFloat = 18
    static let rLarge: CGFloat = 28

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Mastery levels (0...3) mapped to a friendly color ramp used in grids & bars.
enum MasteryPalette {
    static func color(for level: Int) -> Color {
        switch max(0, min(3, level)) {
        case 0: return Color.dyn(0xEDE0D2, 0x322820)
        case 1: return Color.dyn(0xFAD9A6, 0x6E5430)
        case 2: return Color.dyn(0xF6B36B, 0xA9732F)
        default: return Color.dyn(0x2E9E5B, 0x4FBE7A)
        }
    }

    static func label(for level: Int) -> String {
        switch max(0, min(3, level)) {
        case 0: return "New"
        case 1: return "Learning"
        case 2: return "Almost there"
        default: return "Mastered"
        }
    }
}
