import SwiftUI

/// Lace design language: bold, motivational, energetic-but-clean.
/// Coral/red accent (#E4574C), big confident rounded numerals, progress rings,
/// calm off-white surfaces in light mode and deep ink surfaces in dark mode.
/// WCAG-AA contrast in both modes.
enum Theme {

    // MARK: - Brand colors

    /// Primary coral accent — also defined in the asset catalog as AccentColor.
    static let coral = Color(red: 0xE4 / 255.0, green: 0x57 / 255.0, blue: 0x4C / 255.0)
    /// Deeper coral for pressed / emphasis states.
    static let coralDeep = Color(red: 0xC2 / 255.0, green: 0x42 / 255.0, blue: 0x38 / 255.0)

    /// Cool teal secondary — used for "walk" intervals & secondary accents.
    static let teal = Color(red: 0x2E / 255.0, green: 0x9E / 255.0, blue: 0xA6 / 255.0)
    static let tealDeep = Color(red: 0x21 / 255.0, green: 0x79 / 255.0, blue: 0x80 / 255.0)

    // MARK: - Interval hues (consistent everywhere intervals are shown)

    /// Run / jog — energetic coral.
    static let run = coral
    /// Walk — calming teal.
    static let walk = teal
    /// Warmup — warm amber.
    static let warmup = Color(red: 0xE8 / 255.0, green: 0xA5 / 255.0, blue: 0x3A / 255.0)
    /// Cooldown — cool indigo.
    static let cooldown = Color(red: 0x6E / 255.0, green: 0x6C / 255.0, blue: 0xD8 / 255.0)

    static let positive = Color(red: 0x36 / 255.0, green: 0xA9 / 255.0, blue: 0x5E / 255.0)
    static let warning  = Color(red: 0xD9 / 255.0, green: 0x8A / 255.0, blue: 0x1E / 255.0)
    static let danger   = Color(red: 0xCB / 255.0, green: 0x3B / 255.0, blue: 0x3B / 255.0)

    // MARK: - Adaptive surfaces

    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x12 / 255.0, green: 0x13 / 255.0, blue: 0x17 / 255.0)
            : Color(red: 0xF7 / 255.0, green: 0xF5 / 255.0, blue: 0xF3 / 255.0)
    }

    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1D / 255.0, green: 0x1F / 255.0, blue: 0x25 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x2A / 255.0, green: 0x2D / 255.0, blue: 0x35 / 255.0)
            : Color(red: 0xEC / 255.0, green: 0xE9 / 255.0, blue: 0xE4 / 255.0)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF4 / 255.0, green: 0xF4 / 255.0, blue: 0xF6 / 255.0)
            : Color(red: 0x1A / 255.0, green: 0x1C / 255.0, blue: 0x20 / 255.0)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9C / 255.0, green: 0xA2 / 255.0, blue: 0xAC / 255.0)
            : Color(red: 0x60 / 255.0, green: 0x65 / 255.0, blue: 0x6D / 255.0)
    }

    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.07)
    }

    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    // MARK: - Typography

    /// A bold rounded numeral font for big figures & countdowns.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    /// A confident rounded display font.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Card container

/// A rounded, tactile card surface used throughout the app.
struct LaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct LacePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isEnabled
                          ? (configuration.isPressed ? Theme.coralDeep : Theme.coral)
                          : Theme.coral.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (outline) button style

struct LaceSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Theme.coral)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.coral.opacity(configuration.isPressed ? 0.26 : 0.13))
            )
    }
}

// MARK: - Chip modifier

struct LaceChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool
    var color: Color = Theme.coral

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : Theme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? color : Theme.subtleSurface(scheme))
            )
    }
}

extension View {
    func laceChip(selected: Bool, color: Color = Theme.coral) -> some View {
        modifier(LaceChip(selected: selected, color: color))
    }

    /// Standard screen background applied behind feature screens.
    func laceScreenBackground(_ scheme: ColorScheme) -> some View {
        background(Theme.appBackground(scheme).ignoresSafeArea())
    }
}

// MARK: - Section header

struct LaceSectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.coral)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.secondaryText(scheme))
                .textCase(.uppercase)
                .tracking(0.6)
            Spacer(minLength: 0)
        }
    }
}
