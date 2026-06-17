import SwiftUI

/// Recur design language: a calm, modern finance look.
/// Soft off-white surfaces in light mode, deep ink in dark mode,
/// violet accent (#7C5CF0) with a teal secondary used for positive / income hints.
enum RecurTheme {

    // MARK: - Brand colors

    /// Violet accent — also defined in the asset catalog as AccentColor.
    static let violet = Color(red: 0x7C / 255.0, green: 0x5C / 255.0, blue: 0xF0 / 255.0)
    /// Deeper violet for pressed / emphasis.
    static let violetDeep = Color(red: 0x63 / 255.0, green: 0x45 / 255.0, blue: 0xD0 / 255.0)
    /// Soft violet tint for fills / haloes.
    static let violetSoft = Color(red: 0x7C / 255.0, green: 0x5C / 255.0, blue: 0xF0 / 255.0).opacity(0.12)

    /// Teal secondary accent (used for savings / positive signals).
    static let teal = Color(red: 0x2E / 255.0, green: 0xB0 / 255.0, blue: 0xA0 / 255.0)
    /// Amber — trial / warning accent.
    static let amber = Color(red: 0xE6 / 255.0, green: 0x9A / 255.0, blue: 0x2E / 255.0)
    /// Coral — cancel / negative accent.
    static let coral = Color(red: 0xE2 / 255.0, green: 0x5A / 255.0, blue: 0x5A / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: soft cool white in light, deep ink in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x18 / 255.0)
            : Color(red: 0xF6 / 255.0, green: 0xF5 / 255.0, blue: 0xFB / 255.0)
    }

    /// Card surface — sits above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1D / 255.0, green: 0x1D / 255.0, blue: 0x26 / 255.0)
            : Color.white
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x29 / 255.0, green: 0x29 / 255.0, blue: 0x34 / 255.0)
            : Color(red: 0xEC / 255.0, green: 0xEA / 255.0, blue: 0xF4 / 255.0)
    }

    /// Primary text — high contrast in both modes (WCAG AA).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF1 / 255.0, green: 0xF0 / 255.0, blue: 0xF7 / 255.0)
            : Color(red: 0x1B / 255.0, green: 0x18 / 255.0, blue: 0x2A / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9A / 255.0, green: 0x98 / 255.0, blue: 0xAC / 255.0)
            : Color(red: 0x6B / 255.0, green: 0x68 / 255.0, blue: 0x7E / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    static func accent(_ scheme: ColorScheme) -> Color { violet }
}

// MARK: - Card container

/// A rounded, soft card surface used throughout the app.
struct RecurCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(RecurTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(RecurTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct RecurPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isEnabled
                          ? (configuration.isPressed ? RecurTheme.violetDeep : RecurTheme.violet)
                          : RecurTheme.violet.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (violet tint) button style

struct RecurSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(RecurTheme.violet)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(RecurTheme.violet.opacity(configuration.isPressed ? 0.24 : 0.14))
            )
    }
}

// MARK: - Chip style modifier

struct RecurChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : RecurTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? RecurTheme.violet : RecurTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func recurChip(selected: Bool) -> some View { modifier(RecurChip(selected: selected)) }
}

// MARK: - Color <-> hex

extension Color {
    /// Builds a Color from a 6-digit hex string like "7C5CF0".
    /// Falls back to the violet accent for malformed input (never crashes).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        var value: UInt64 = 0
        if cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) {
            let r = Double((value & 0xFF0000) >> 16) / 255.0
            let g = Double((value & 0x00FF00) >> 8) / 255.0
            let b = Double(value & 0x0000FF) / 255.0
            self = Color(red: r, green: g, blue: b)
        } else {
            self = RecurTheme.violet
        }
    }
}
