import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A color that adapts between light and dark interface styles.
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

/// The visual identity for Sigma — a premium calculator: warm paper in light,
/// near-black graphite in dark, with a single warm amber accent.
enum Theme {
    /// Matches the AccentColor asset (0xF2A33C, warm amber).
    static let accent = Color(hex: 0xF2A33C)
    static let accentInk = Color(hex: 0x1A1206)

    /// App background — soft warm paper / deep graphite.
    static let bg = Color.dyn(0xF4F2EE, 0x121212)
    /// Raised surfaces (cards, the display, key backgrounds).
    static let surface = Color.dyn(0xFFFFFF, 0x1E1E1F)
    /// Slightly recessed surface used behind the keypad.
    static let surfaceDeep = Color.dyn(0xEDEAE3, 0x171718)
    /// Standard tactile key color (digits / display chrome).
    static let key = Color.dyn(0xFFFFFF, 0x2A2A2C)
    /// Function / operator keys — a touch heavier.
    static let keyFunction = Color.dyn(0xE6E2DA, 0x37373A)

    static let ink = Color.dyn(0x1B1A17, 0xF3F1EC)
    static let inkSoft = Color.dyn(0x6E6A60, 0x9C988E)
    static let inkFaint = Color.dyn(0x9A958A, 0x6B675F)
    static let hairline = Color.dyn(0xE3DFD6, 0x303032)

    static let good = Color.dyn(0x2E8B57, 0x57C98A)
    static let warn = Color.dyn(0xC9821B, 0xE9A94A)
    static let bad = Color.dyn(0xC0392B, 0xF06A5A)

    static let keyShadow = Color.dyn(0xCFC9BC, 0x000000)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let cornerCard: CGFloat = 18
    static let cornerKey: CGFloat = 16
}

/// Extra premium themes unlocked by Pro. The base theme keeps the amber identity.
enum AppTheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case graphite = "Graphite"
    case paper = "Paper"
    case solar = "Solar"

    var id: String { rawValue }
    var requiresPro: Bool { self != .classic }

    /// Accent color for this theme variant.
    var accent: Color {
        switch self {
        case .classic: return Theme.accent
        case .graphite: return Color(hex: 0x8FA0B3)
        case .paper:    return Color(hex: 0xB07A3E)
        case .solar:    return Color(hex: 0xFF7A1A)
        }
    }

    var blurb: String {
        switch self {
        case .classic:  return "Warm amber, the signature look."
        case .graphite: return "Cool steel-blue keys on slate."
        case .paper:    return "Muted earthen tones on paper."
        case .solar:    return "Bright sunrise orange accents."
        }
    }
}
