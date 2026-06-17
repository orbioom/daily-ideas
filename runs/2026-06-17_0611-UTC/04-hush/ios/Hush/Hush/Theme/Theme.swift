import SwiftUI

/// Hush design language: a calm, nocturnal sleep-sounds look.
/// Soft teal accent (#2E8E9E), gentle glows, near-black surfaces in dark mode
/// (the primary experience) and a soft cool off-white in light mode.
/// WCAG-AA contrast in both modes.
enum HushTheme {

    // MARK: - Brand colors

    /// Primary calm-teal accent — also defined in the asset catalog as AccentColor.
    static let teal = Color(red: 0x2E / 255.0, green: 0x8E / 255.0, blue: 0x9E / 255.0)

    /// A deeper teal used for pressed / emphasis states.
    static let tealDeep = Color(red: 0x22 / 255.0, green: 0x6C / 255.0, blue: 0x79 / 255.0)

    /// A soft lavender-indigo secondary used for nocturnal accents & glows.
    static let indigo = Color(red: 0x6E / 255.0, green: 0x78 / 255.0, blue: 0xC4 / 255.0)

    /// Warm amber used sparingly for the active sleep-timer / "winding down" state.
    static let amber = Color(red: 0xE0 / 255.0, green: 0xA4 / 255.0, blue: 0x55 / 255.0)

    static let positive = Color(red: 0x4F / 255.0, green: 0xB0 / 255.0, blue: 0x88 / 255.0)
    static let danger   = Color(red: 0xCB / 255.0, green: 0x5A / 255.0, blue: 0x5A / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: soft cool off-white in light, deep ink in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x0C / 255.0, green: 0x10 / 255.0, blue: 0x16 / 255.0)
            : Color(red: 0xF3 / 255.0, green: 0xF5 / 255.0, blue: 0xF7 / 255.0)
    }

    /// Card surface — sits above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x16 / 255.0, green: 0x1C / 255.0, blue: 0x24 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    /// Subtle raised surface for chips / fields / inactive tiles.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x20 / 255.0, green: 0x28 / 255.0, blue: 0x32 / 255.0)
            : Color(red: 0xE7 / 255.0, green: 0xEB / 255.0, blue: 0xEF / 255.0)
    }

    /// Primary text — high contrast in both modes.
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xED / 255.0, green: 0xF1 / 255.0, blue: 0xF5 / 255.0)
            : Color(red: 0x18 / 255.0, green: 0x1E / 255.0, blue: 0x26 / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9B / 255.0, green: 0xA6 / 255.0, blue: 0xB2 / 255.0)
            : Color(red: 0x5C / 255.0, green: 0x65 / 255.0, blue: 0x70 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    /// A faint track color for sliders & meters.
    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    // MARK: - Typography helpers

    /// A rounded numeral font for the big countdown / volume figures.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Card container

/// A rounded, calm card surface used throughout the app.
struct HushCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(HushTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(HushTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct HushPrimaryButtonStyle: ButtonStyle {
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
                          ? (configuration.isPressed ? HushTheme.tealDeep : HushTheme.teal)
                          : HushTheme.teal.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (teal outline) button style

struct HushSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(HushTheme.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HushTheme.teal.opacity(configuration.isPressed ? 0.26 : 0.13))
            )
    }
}

// MARK: - Chip style modifier

struct HushChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : HushTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? HushTheme.teal : HushTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func hushChip(selected: Bool) -> some View { modifier(HushChip(selected: selected)) }

    /// Standard screen background applied behind feature screens.
    func hushScreenBackground(_ scheme: ColorScheme) -> some View {
        background(HushTheme.appBackground(scheme).ignoresSafeArea())
    }
}

// MARK: - Section header

struct HushSectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HushTheme.teal)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HushTheme.secondaryText(scheme))
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer(minLength: 0)
        }
    }
}
