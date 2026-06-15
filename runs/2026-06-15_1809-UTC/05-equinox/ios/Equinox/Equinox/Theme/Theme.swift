import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Resolves a different hex per interface style so colors stay legible in light and dark.
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

/// Equinox's visual identity: warm, dignified, botanical — a dawn palette moving from
/// dusk-violet into warm marigold/peach. Adult and reassuring, never clinical-cold.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xFBF4EC, 0x14100D)
    static let surface = Color.dyn(0xFFFFFF, 0x201A15)
    static let surfaceAlt = Color.dyn(0xF4E9DC, 0x2A221B)

    // Ink (text)
    static let ink = Color.dyn(0x2A1F18, 0xF5EDE3)
    static let inkSoft = Color.dyn(0x6A5849, 0xC9B9A7)
    static let inkFaint = Color.dyn(0x988372, 0x8C7A68)

    // Accent — warm marigold (matches AccentColor 0xD88A55)
    static let accent = Color(hex: 0xD88A55)
    static let accentSoft = Color.dyn(0xF6E3D0, 0x3A2A1E)
    static let accentDeep = Color.dyn(0xB96A38, 0xE6A877)

    // A complementary dusk-violet for the dawn gradient.
    static let dusk = Color.dyn(0x7A6494, 0x9B82B8)

    // Lines & status
    static let hairline = Color.dyn(0xEADCCC, 0x342A22)
    static let good = Color.dyn(0x4E8C6A, 0x7CC79C)
    static let warn = Color.dyn(0xC2862A, 0xE6B765)
    static let bad = Color.dyn(0xC0584A, 0xE38B7C)

    /// A calm dawn gradient for hero surfaces: dusk-violet → marigold → peach.
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x6E5A88), Color(hex: 0xD88A55), Color(hex: 0xE9A878)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Warm gradient used for hot-flash intensity heat.
    static func heatColor(_ intensity: Double) -> Color {
        // 0 → calm peach, 1 → deep marigold/coral
        let clamped = max(0, min(1, intensity))
        return Color.dyn(
            lerpHex(0xF6E3D0, 0xD8674A, clamped),
            lerpHex(0x3A2A1E, 0xE3724F, clamped)
        )
    }

    private static func lerpHex(_ a: UInt, _ b: UInt, _ t: Double) -> UInt {
        func chan(_ shift: UInt) -> UInt {
            let av = Double((a >> shift) & 0xFF)
            let bv = Double((b >> shift) & 0xFF)
            let v = av + (bv - av) * t
            return UInt(max(0, min(255, v.rounded())))
        }
        return (chan(16) << 16) | (chan(8) << 8) | chan(0)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

/// Card surface used across the app for a cohesive look.
struct CardBackground: ViewModifier {
    var fill: Color = Theme.surface
    var corner: CGFloat = Theme.corner
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(fill: Color = Theme.surface, corner: CGFloat = Theme.corner) -> some View {
        modifier(CardBackground(fill: fill, corner: corner))
    }
}
