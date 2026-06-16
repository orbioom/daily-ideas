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

/// Encore's visual identity: night / stage-lights — a dark auditorium washed in magenta→purple glow,
/// with ticket-stub cards as the recurring motif.
enum Theme {
    // Backgrounds — deep house lights down.
    static let bg = Color.dyn(0xF7F0F6, 0x1A0A23)
    static let surface = Color.dyn(0xFFFFFF, 0x271133)
    static let surfaceAlt = Color.dyn(0xF0E4EF, 0x331845)

    // Ink (text)
    static let ink = Color.dyn(0x231029, 0xF6ECF4)
    static let inkSoft = Color.dyn(0x6A5470, 0xC7AED2)
    static let inkFaint = Color.dyn(0x9A85A0, 0x8C6E9C)

    // Accent — stage magenta (matches AccentColor 0xC2459B)
    static let accent = Color(hex: 0xC2459B)
    static let accentSoft = Color.dyn(0xF6DCEE, 0x3A1C4A)
    static let accentDeep = Color.dyn(0x9C2F7C, 0xDB73BE)

    /// Purple companion used in gradients and the secondary chart series.
    static let purple = Color.dyn(0x7A3FC0, 0xB07BE8)

    // Lines & status
    static let hairline = Color.dyn(0xE7D6E6, 0x3A2148)
    static let good = Color.dyn(0x2E9E6B, 0x5BD9A0)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)
    static let gold = Color.dyn(0xC79A2E, 0xF1D173)

    /// A magenta→purple gradient for hero surfaces (paywall, onboarding, ticket headers).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xE05CB4), Color(hex: 0xC2459B), Color(hex: 0x7A3FC0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Per-seed ticket-stub gradients so each show card reads with its own stage colour.
    static func ticketGradient(seed: Int) -> LinearGradient {
        let pair = ticketColors(seed: seed)
        return LinearGradient(colors: [pair.0, pair.1],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }

    /// A stable two-colour pair keyed by a stored colorSeed (0...n). Always vivid enough for white ink.
    static func ticketColors(seed: Int) -> (Color, Color) {
        let ramps: [(UInt, UInt)] = [
            (0xD13A8E, 0x7A2EAE),
            (0xB13FB0, 0x5C3FC0),
            (0xE0567A, 0xB13F9E),
            (0x8A3FD0, 0x4A3FB0),
            (0xD1487A, 0x8A2EAE),
            (0xC2459B, 0x6A3FC0),
            (0xE0708A, 0xC2459B),
            (0x9C2F7C, 0x3F4FC0)
        ]
        let count = ramps.count
        guard count > 0 else { return (accent, purple) }
        let idx = ((seed % count) + count) % count
        let r = ramps[idx]
        return (Color(hex: r.0), Color(hex: r.1))
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
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
