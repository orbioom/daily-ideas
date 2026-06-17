import SwiftUI

/// Abode design language: a calm, confident fintech look.
/// Trustworthy navy/blue accent (#2D6CB3), monospaced figures for money, generous
/// whitespace, soft cards. WCAG-AA contrast in both light and dark modes.
enum AbodeTheme {

    // MARK: - Brand colors

    /// Primary accent — also defined in the asset catalog as AccentColor.
    static let accent = Color(red: 0x2D / 255.0, green: 0x6C / 255.0, blue: 0xB3 / 255.0)
    /// A deeper navy for pressed / emphasis states.
    static let accentDeep = Color(red: 0x22 / 255.0, green: 0x53 / 255.0, blue: 0x8C / 255.0)
    /// A soft sky tint for chips / highlights.
    static let accentSoft = Color(red: 0x5E / 255.0, green: 0x96 / 255.0, blue: 0xD6 / 255.0)

    // MARK: - Payment breakdown hues (consistent across every chart & legend)

    static let principalInterest = Color(red: 0x2D / 255.0, green: 0x6C / 255.0, blue: 0xB3 / 255.0) // navy
    static let propertyTax        = Color(red: 0x3F / 255.0, green: 0xA9 / 255.0, blue: 0x8C / 255.0) // teal-green
    static let insurance          = Color(red: 0xE2 / 255.0, green: 0xA1 / 255.0, blue: 0x3C / 255.0) // amber
    static let pmi                = Color(red: 0xC9 / 255.0, green: 0x5B / 255.0, blue: 0x4E / 255.0) // clay red
    static let hoa                = Color(red: 0x8A / 255.0, green: 0x6F / 255.0, blue: 0xC6 / 255.0) // violet

    /// Semantic state hues.
    static let positive = Color(red: 0x2F / 255.0, green: 0x9E / 255.0, blue: 0x5E / 255.0)
    static let warning  = Color(red: 0xCB / 255.0, green: 0x8A / 255.0, blue: 0x1E / 255.0)
    static let danger   = Color(red: 0xC2 / 255.0, green: 0x3B / 255.0, blue: 0x3B / 255.0)

    // MARK: - Adaptive surfaces

    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x10 / 255.0, green: 0x14 / 255.0, blue: 0x1A / 255.0)
            : Color(red: 0xF4 / 255.0, green: 0xF6 / 255.0, blue: 0xFA / 255.0)
    }

    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1A / 255.0, green: 0x1F / 255.0, blue: 0x27 / 255.0)
            : Color.white
    }

    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x26 / 255.0, green: 0x2C / 255.0, blue: 0x36 / 255.0)
            : Color(red: 0xE9 / 255.0, green: 0xEE / 255.0, blue: 0xF5 / 255.0)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF2 / 255.0, green: 0xF4 / 255.0, blue: 0xF8 / 255.0)
            : Color(red: 0x16 / 255.0, green: 0x1C / 255.0, blue: 0x26 / 255.0)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x96 / 255.0, green: 0x9E / 255.0, blue: 0xAB / 255.0)
            : Color(red: 0x5C / 255.0, green: 0x64 / 255.0, blue: 0x70 / 255.0)
    }

    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    // MARK: - Typography

    /// Monospaced figure font for money — aligns digits, fintech feel.
    static func figure(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
}

// MARK: - Card container

/// A soft rounded card used throughout the app.
struct AbodeCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AbodeTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(AbodeTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Button styles

struct AbodePrimaryButtonStyle: ButtonStyle {
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
                          ? (configuration.isPressed ? AbodeTheme.accentDeep : AbodeTheme.accent)
                          : AbodeTheme.accent.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AbodeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AbodeTheme.accentDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AbodeTheme.accent.opacity(configuration.isPressed ? 0.26 : 0.13))
            )
    }
}

// MARK: - Chip modifier

struct AbodeChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : AbodeTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? AbodeTheme.accent : AbodeTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func abodeChip(selected: Bool) -> some View { modifier(AbodeChip(selected: selected)) }

    func abodeScreenBackground(_ scheme: ColorScheme) -> some View {
        background(AbodeTheme.appBackground(scheme).ignoresSafeArea())
    }
}

// MARK: - Section header

struct AbodeSectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AbodeTheme.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer(minLength: 0)
        }
    }
}
