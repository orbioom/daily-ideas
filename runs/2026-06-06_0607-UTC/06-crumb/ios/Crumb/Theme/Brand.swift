import SwiftUI

/// Orbioom brand system for Crumb: color tokens, typography, and motion in one place.
/// Colors resolve per color scheme so light and dark are both first-class without
/// hand-authoring dozens of asset color sets. "Conjured, not just coded."
enum Brand {

    // MARK: - Color resolution

    /// A color that resolves to `light` in light mode and `dark` in dark mode.
    static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }

    // Mist backgrounds — never pure white. Dark variants stay calm, never pure black.
    static let mist1 = dynamic(0xEDEEF3, 0x14151B)
    static let mist2 = dynamic(0xE7E9F0, 0x191B22)
    static let mist3 = dynamic(0xECEEF2, 0x1E2027)

    // Text inks.
    static let text  = dynamic(0x1B1D2A, 0xF2F3F8)
    static let text2 = dynamic(0x565A70, 0xB4B8CC)
    static let text3 = dynamic(0x8B8FA3, 0x7C8095)

    // Restrained green — success / active / "fed" only, never decoration.
    static let live  = dynamic(0x86C79A, 0x86C79A)
    // Warm caution tone — used sparingly to mark "needs feeding / overdue".
    static let warm  = dynamic(0xC77E7E, 0xD79A9A)
    // Rare "magic" accent.
    static let magic = dynamic(0x4FB98C, 0x5EF0B0)

    // Glass + edges.
    static let glassStroke = dynamic(0xFFFFFF, 0x3A3D49)
    static let cardShadow  = Color(UIColor { t in
        UIColor(hex: t.userInterfaceStyle == .dark ? 0x000000 : 0x282C50)
            .withAlphaComponent(t.userInterfaceStyle == .dark ? 0.45 : 0.14)
    })

    /// Ink primary-action gradient (180°, #3A3E4C -> #23262F). The one focal action per screen.
    static let inkGradient = LinearGradient(
        colors: [Color(hex: 0x3A3E4C), Color(hex: 0x23262F)],
        startPoint: .top, endPoint: .bottom
    )

    /// Layered mist page background.
    static var pageBackground: some View {
        LinearGradient(colors: [mist1, mist2, mist3],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    // MARK: - Motion

    /// Orbioom easing — slow, purposeful. cubic-bezier(0.16, 1, 0.3, 1).
    static func ease(_ duration: Double = 0.45) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }

    // MARK: - Typography

    /// Monospaced figure styling for grams, percentages, times — system monospaced design.
    /// No mono font file is bundled, so this uses the system monospaced design.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - Ingredient role palette

    /// Calm, distinct hues used for ingredient role chips and dots.
    static func roleColor(_ role: Role) -> Color {
        switch role {
        case .flour:  return Color(hex: 0xB6843E)   // wheat amber
        case .water:  return Color(hex: 0x4F8AA8)   // hydration blue
        case .levain: return Color(hex: 0x5E8A6A)   // living green
        case .salt:   return Color(hex: 0x6B5E8A)   // mineral violet
        case .other:  return Color(hex: 0x9A5A4A)   // seed/oil rust
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension Color {
    init(hex: UInt32) { self.init(UIColor(hex: hex)) }
}
