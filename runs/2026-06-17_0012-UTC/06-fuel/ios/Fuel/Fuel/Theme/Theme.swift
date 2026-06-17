import SwiftUI

/// Fuel design language: an energetic but clean fitness look.
/// Warm orange accent (#EF6A38), bold numerals, calm off-white surfaces in light
/// mode and deep slate surfaces in dark mode. WCAG-AA contrast in both modes.
enum FuelTheme {

    // MARK: - Brand colors

    /// Primary orange accent — also defined in the asset catalog as AccentColor.
    static let orange = Color(red: 0xEF / 255.0, green: 0x6A / 255.0, blue: 0x38 / 255.0)

    /// A deeper orange used for pressed / emphasis states.
    static let orangeDeep = Color(red: 0xCE / 255.0, green: 0x55 / 255.0, blue: 0x27 / 255.0)

    /// Cool teal secondary accent — pairs with the warm orange.
    static let teal = Color(red: 0x2F / 255.0, green: 0x9C / 255.0, blue: 0x95 / 255.0)
    static let tealDeep = Color(red: 0x23 / 255.0, green: 0x78 / 255.0, blue: 0x73 / 255.0)

    // MARK: - Macro hues (consistent across all charts & bars)

    static let protein = Color(red: 0xEF / 255.0, green: 0x6A / 255.0, blue: 0x38 / 255.0) // orange
    static let carbs   = Color(red: 0x3E / 255.0, green: 0x9B / 255.0, blue: 0xC9 / 255.0) // blue
    static let fat     = Color(red: 0xF2 / 255.0, green: 0xB1 / 255.0, blue: 0x3C / 255.0) // amber

    /// Positive (on-track / surplus where desired) and warning hues.
    static let positive = Color(red: 0x3F / 255.0, green: 0xA9 / 255.0, blue: 0x5C / 255.0)
    static let warning  = Color(red: 0xD9 / 255.0, green: 0x8A / 255.0, blue: 0x1E / 255.0)
    static let danger   = Color(red: 0xCB / 255.0, green: 0x3B / 255.0, blue: 0x3B / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: cool off-white in light, deep slate in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x14 / 255.0, green: 0x16 / 255.0, blue: 0x1A / 255.0)
            : Color(red: 0xF6 / 255.0, green: 0xF5 / 255.0, blue: 0xF2 / 255.0)
    }

    /// Card surface — sits above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1E / 255.0, green: 0x21 / 255.0, blue: 0x27 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x2A / 255.0, green: 0x2E / 255.0, blue: 0x36 / 255.0)
            : Color(red: 0xEC / 255.0, green: 0xEA / 255.0, blue: 0xE5 / 255.0)
    }

    /// Primary text — high contrast in both modes.
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF3 / 255.0, green: 0xF4 / 255.0, blue: 0xF6 / 255.0)
            : Color(red: 0x1C / 255.0, green: 0x1F / 255.0, blue: 0x24 / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9A / 255.0, green: 0xA1 / 255.0, blue: 0xAB / 255.0)
            : Color(red: 0x66 / 255.0, green: 0x6B / 255.0, blue: 0x73 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.09)
            : Color.black.opacity(0.07)
    }

    /// A faint track color for rings & bars.
    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.07)
    }

    // MARK: - Typography helpers

    /// A bold, rounded numeral font for the big calorie / weight figures.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Card container

/// A rounded, tactile card surface used throughout the app.
struct FuelCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(FuelTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(FuelTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct FuelPrimaryButtonStyle: ButtonStyle {
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
                          ? (configuration.isPressed ? FuelTheme.orangeDeep : FuelTheme.orange)
                          : FuelTheme.orange.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (teal outline) button style

struct FuelSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(FuelTheme.tealDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(FuelTheme.teal.opacity(configuration.isPressed ? 0.28 : 0.14))
            )
    }
}

// MARK: - Chip style modifier

struct FuelChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : FuelTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? FuelTheme.orange : FuelTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func fuelChip(selected: Bool) -> some View { modifier(FuelChip(selected: selected)) }

    /// Standard screen background applied behind feature screens.
    func fuelScreenBackground(_ scheme: ColorScheme) -> some View {
        background(FuelTheme.appBackground(scheme).ignoresSafeArea())
    }
}

// MARK: - Section header

struct FuelSectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FuelTheme.orange)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FuelTheme.secondaryText(scheme))
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer(minLength: 0)
        }
    }
}
