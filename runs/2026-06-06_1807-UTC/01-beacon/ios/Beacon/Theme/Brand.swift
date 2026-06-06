import SwiftUI

/// Orbioom brand system: color tokens, typography, motion, and shared surface
/// primitives in one place. Colors resolve per color scheme so light and dark
/// are both first-class. "Conjured, not just coded."
enum Brand {

    // MARK: - Color resolution

    /// A color that resolves to `light` in light mode and `dark` in dark mode.
    static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }

    // Mist backgrounds — never pure white; dark variants stay calm, never pure black.
    static let mist1 = dynamic(0xEDEEF3, 0x14151B)
    static let mist2 = dynamic(0xE7E9F0, 0x191B22)
    static let mist3 = dynamic(0xECEEF2, 0x1E2027)

    // Text inks.
    static let text  = dynamic(0x1B1D2A, 0xF2F3F8)
    static let text2 = dynamic(0x565A70, 0xB4B8CC)
    static let text3 = dynamic(0x8B8FA3, 0x7C8095)

    // Restrained semantic accents — live/success green is rare and meaningful.
    static let live   = dynamic(0x4FB98C, 0x86C79A)
    static let magic  = dynamic(0x3E9E78, 0x5EF0B0)
    static let warn   = dynamic(0xC08A3E, 0xE0B86A)
    static let danger = dynamic(0xC0553E, 0xE08A78)
    static let info   = dynamic(0x4E6BA8, 0x8FAEE8)

    // Glass + edges.
    static let glassStroke = dynamic(0xFFFFFF, 0x3A3D49)
    static let hairline    = dynamic(0xD7DAE4, 0x2C2F38)
    static let cardShadow  = Color(UIColor { t in
        UIColor(hex: t.userInterfaceStyle == .dark ? 0x000000 : 0x282C50)
            .withAlphaComponent(t.userInterfaceStyle == .dark ? 0.45 : 0.12)
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

    /// Monospaced figures for numbers/data — JetBrains Mono feel via system mono design.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
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

// MARK: - Shared surface primitives

/// A calm liquid-glass card surface.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Brand.cardShadow, radius: 14, x: 0, y: 8)
    }
}

extension View {
    /// Wrap any view in the standard glass card surface.
    func glassCard(padding: CGFloat = 16) -> some View {
        GlassCard(padding: padding) { self }
    }
}

/// The one focal action per screen — ink gradient, white label.
struct InkButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Brand.inkGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .shadow(color: Brand.cardShadow, radius: 8, x: 0, y: 4)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }
}

/// Quiet glass secondary button.
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }
}

/// Eyebrow label — mono, tertiary, tracked.
struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Brand.mono(12, weight: .medium))
            .tracking(1.4)
            .foregroundStyle(Brand.text3)
    }
}

/// A small live status dot with soft glow.
struct StatusDot: View {
    var color: Color = Brand.live
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.7), radius: 4)
            .accessibilityHidden(true)
    }
}

/// Standard empty-state presentation.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }
}
