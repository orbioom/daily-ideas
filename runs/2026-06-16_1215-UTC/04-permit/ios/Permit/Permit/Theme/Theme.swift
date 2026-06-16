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

    /// Dynamic color that resolves differently in light and dark mode.
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

/// Central design language for Permit — a clean, trustworthy "study green" identity.
enum Theme {
    // Brand accent — MUST match AccentColor.colorset (0x178A4C).
    static let accent = Color(hex: 0x178A4C)
    static let accentDeep = Color.dyn(0x0F6B3A, 0x21A35E)

    // Surfaces
    static let bg = Color.dyn(0xF4F7F4, 0x0E1411)
    static let surface = Color.dyn(0xFFFFFF, 0x18211C)
    static let surfaceAlt = Color.dyn(0xEFF3EF, 0x202C25)
    static let hairline = Color.dyn(0xDDE5DD, 0x2C3A32)

    // Text
    static let ink = Color.dyn(0x122019, 0xEAF3EC)
    static let inkSoft = Color.dyn(0x556257, 0x9DB0A2)
    static let onAccent = Color.white

    // Semantic
    static let good = Color.dyn(0x1B8A4C, 0x32C06E)
    static let warn = Color.dyn(0xC78A12, 0xE5B146)
    static let bad = Color.dyn(0xC23B2E, 0xF06A5C)

    // Sign rendering palette (consistent across the Signs library)
    static let signRed = Color(hex: 0xC0392B)
    static let signYellow = Color(hex: 0xF1C40F)
    static let signOrange = Color(hex: 0xE67E22)
    static let signGreen = Color(hex: 0x1E824C)
    static let signBlue = Color(hex: 0x2471A3)
    static let signWhite = Color.white
    static let signBlack = Color(hex: 0x1A1A1A)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x178A4C), Color(hex: 0x0E6B3A)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Corner radii
    static let rSmall: CGFloat = 10
    static let rMedium: CGFloat = 16
    static let rLarge: CGFloat = 24

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A reusable themed card container.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}
