import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Dynamic color that adapts to light / dark interface styles.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Crest visual identity — a calm felt-green card table with gold-green accents and rounded type.
enum Theme {
    // Brand accent (matches AccentColor in Assets: #1FA463)
    static let accent = Color(hex: 0x1FA463)
    static let accentDeep = Color.dyn(0x16794A, 0x2FBF7A)
    static let gold = Color.dyn(0xC9A227, 0xE6C453)

    // Surfaces & backgrounds
    static let bg = Color.dyn(0xEAF6EF, 0x06140D)
    static let surface = Color.dyn(0xFFFFFF, 0x10241A)
    static let surfaceSoft = Color.dyn(0xF1FAF4, 0x0C1D14)

    // Ink (text)
    static let ink = Color.dyn(0x10241A, 0xEAF6EF)
    static let inkSoft = Color.dyn(0x4C6358, 0x9FBDAE)
    static let inkFaint = Color.dyn(0x7C9387, 0x6E8A7C)
    static let hairline = Color.dyn(0xD3E6DA, 0x21392C)

    // Semantic
    static let good = Color.dyn(0x1FA463, 0x2FBF7A)
    static let warn = Color.dyn(0xC9821F, 0xE0A347)
    static let bad = Color.dyn(0xC23B3B, 0xE36A6A)

    // Card faces
    static let cardFace = Color.dyn(0xFFFFFF, 0xF4F1E8)
    static let cardBack1 = Color.dyn(0x1FA463, 0x176C46)
    static let cardBack2 = Color.dyn(0x16794A, 0x0E4730)
    static let suitRed = Color(hex: 0xC23B3B)
    static let suitBlack = Color(hex: 0x1B2A22)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dyn(0x1FA463, 0x176C46), Color.dyn(0x16794A, 0x0E4730)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Corner radii
    static let radiusCard: CGFloat = 9
    static let radiusTile: CGFloat = 18
    static let radiusButton: CGFloat = 14

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Available felt table themes (a Pro perk beyond the default).
enum FeltTheme: String, CaseIterable, Identifiable {
    case classic = "Classic Green"
    case midnight = "Midnight Blue"
    case sunset = "Warm Sunset"
    case slate = "Cool Slate"

    var id: String { rawValue }
    var isPro: Bool { self != .classic }

    /// Top/bottom gradient stops for the felt surface (light, dark).
    func gradient(dark: Bool) -> LinearGradient {
        let stops: [Color]
        switch self {
        case .classic:
            stops = dark ? [Color(hex: 0x0F3C28), Color(hex: 0x06140D)]
                         : [Color(hex: 0x1B7A50), Color(hex: 0x115C3B)]
        case .midnight:
            stops = dark ? [Color(hex: 0x132A47), Color(hex: 0x081427)]
                         : [Color(hex: 0x214C7A), Color(hex: 0x16375C)]
        case .sunset:
            stops = dark ? [Color(hex: 0x4A2A1E), Color(hex: 0x1E0F09)]
                         : [Color(hex: 0xB6603A), Color(hex: 0x8A4226)]
        case .slate:
            stops = dark ? [Color(hex: 0x2A3138), Color(hex: 0x12161A)]
                         : [Color(hex: 0x56636E), Color(hex: 0x3C454D)]
        }
        return LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
    }
}
