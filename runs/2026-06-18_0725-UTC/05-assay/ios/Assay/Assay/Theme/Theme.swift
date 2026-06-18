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

    /// Dynamic color that resolves differently for light and dark mode.
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

/// Central design language for Assay — clean clinical / precise.
/// Teal-cyan accent, crisp cards, calm and trustworthy.
enum Theme {
    // Brand
    static let accent = Color(hex: 0x0E9AA8)
    static let accentSoft = Color.dyn(0xCDEBEE, 0x103338)

    // Surfaces
    static let bg = Color.dyn(0xE9F6F7, 0x041416)
    static let surface = Color.dyn(0xFFFFFF, 0x0C1E22)
    static let surfaceAlt = Color.dyn(0xF3FAFB, 0x0A181B)
    static let hairline = Color.dyn(0xD3E6E8, 0x16323A)

    // Ink
    static let ink = Color.dyn(0x0A2024, 0xEAF6F7)
    static let inkSoft = Color.dyn(0x4A6469, 0x90AEB3)
    static let inkFaint = Color.dyn(0x7C969B, 0x5E787D)

    // Status (calm, not alarming)
    static let good = Color.dyn(0x149C7A, 0x39C9A2)     // optimal
    static let okay = Color.dyn(0x2E8FB0, 0x4FB6D6)     // in standard range
    static let warn = Color.dyn(0xC98A2B, 0xE3B25A)     // borderline
    static let bad = Color.dyn(0xC9543E, 0xE08471)      // out of range

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x0E9AA8), Color(hex: 0x1FBFC9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 9

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
}

/// Reusable card surface with the Assay look.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func assayCard(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}
