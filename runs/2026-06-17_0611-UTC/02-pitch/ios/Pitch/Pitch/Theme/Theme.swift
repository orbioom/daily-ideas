import SwiftUI

/// Pitch design language: a dark studio aesthetic with a precise, instrument-like
/// feel. Indigo accent (#5B6CF0), deep charcoal surfaces in dark mode, calm
/// near-white surfaces in light mode, and monospaced numerals for cents / BPM /
/// Hz readouts. Light + dark are both first-class with WCAG-AA contrast.
enum PitchTheme {

    // MARK: - Brand colors

    /// Primary indigo accent — also defined in the asset catalog as AccentColor.
    static let indigo = Color(red: 0x5B / 255.0, green: 0x6C / 255.0, blue: 0xF0 / 255.0)
    /// A deeper indigo for pressed / emphasis states.
    static let indigoDeep = Color(red: 0x44 / 255.0, green: 0x54 / 255.0, blue: 0xD6 / 255.0)
    /// A soft indigo glow used behind highlighted elements.
    static let indigoGlow = Color(red: 0x7E / 255.0, green: 0x8C / 255.0, blue: 0xFF / 255.0)

    /// In-tune green (glowing confirmation).
    static let inTune = Color(red: 0x35 / 255.0, green: 0xC7 / 255.0, blue: 0x59 / 255.0)
    /// Slightly off — amber.
    static let nearTune = Color(red: 0xE6 / 255.0, green: 0xB0 / 255.0, blue: 0x33 / 255.0)
    /// Far off — coral.
    static let offTune = Color(red: 0xE5 / 255.0, green: 0x59 / 255.0, blue: 0x53 / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: deep studio charcoal in dark, soft off-white in light.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x0E / 255.0, green: 0x0F / 255.0, blue: 0x14 / 255.0)
            : Color(red: 0xF4 / 255.0, green: 0xF5 / 255.0, blue: 0xF9 / 255.0)
    }

    /// Card surface — sits above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x18 / 255.0, green: 0x1A / 255.0, blue: 0x22 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x23 / 255.0, green: 0x26 / 255.0, blue: 0x30 / 255.0)
            : Color(red: 0xEA / 255.0, green: 0xEC / 255.0, blue: 0xF2 / 255.0)
    }

    /// Primary text — high contrast in both modes.
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF2 / 255.0, green: 0xF3 / 255.0, blue: 0xF7 / 255.0)
            : Color(red: 0x18 / 255.0, green: 0x1B / 255.0, blue: 0x24 / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9B / 255.0, green: 0xA1 / 255.0, blue: 0xB2 / 255.0)
            : Color(red: 0x5F / 255.0, green: 0x64 / 255.0, blue: 0x72 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    /// Faint track color for gauges & arcs.
    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    // MARK: - Typography helpers

    /// Monospaced numerals for cents / BPM / Hz readouts so digits don't jitter.
    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// A bold rounded font for big note names.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Card container

/// A rounded, tactile card surface used throughout the app.
struct PitchCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(PitchTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(PitchTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct PitchPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled
                          ? (configuration.isPressed ? PitchTheme.indigoDeep : PitchTheme.indigo)
                          : PitchTheme.indigo.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (indigo outline) button style

struct PitchSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(PitchTheme.indigo)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(PitchTheme.indigo.opacity(configuration.isPressed ? 0.26 : 0.13))
            )
    }
}

// MARK: - Chip style modifier

struct PitchChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : PitchTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? PitchTheme.indigo : PitchTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func pitchChip(selected: Bool) -> some View { modifier(PitchChip(selected: selected)) }

    /// Standard screen background applied behind feature screens.
    func pitchScreenBackground(_ scheme: ColorScheme) -> some View {
        background(PitchTheme.appBackground(scheme).ignoresSafeArea())
    }
}

// MARK: - Section header

struct PitchSectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PitchTheme.indigo)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PitchTheme.secondaryText(scheme))
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer(minLength: 0)
        }
    }
}
