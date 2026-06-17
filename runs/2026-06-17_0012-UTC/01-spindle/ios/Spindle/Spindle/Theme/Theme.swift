import SwiftUI

/// Spindle design language: a calm, premium card-table feel.
/// Deep emerald felt, cream cards with crisp ranks/pips, gold-ish accent
/// for highlights. Three selectable felt themes. Cohesive across every screen.
enum SpindleTheme {

    // MARK: - Brand colors

    /// Emerald accent — also defined in the asset catalog as AccentColor (#1F9E6E).
    static let emerald = Color(red: 0x1F / 255.0, green: 0x9E / 255.0, blue: 0x6E / 255.0)
    static let emeraldDeep = Color(red: 0x16 / 255.0, green: 0x77 / 255.0, blue: 0x53 / 255.0)

    /// Warm gold accent for selections / highlights / hints.
    static let gold = Color(red: 0xD8 / 255.0, green: 0xA8 / 255.0, blue: 0x4A / 255.0)
    static let goldDeep = Color(red: 0xB4 / 255.0, green: 0x88 / 255.0, blue: 0x32 / 255.0)

    // MARK: - Adaptive surfaces (chrome / sheets / settings)

    /// App background for non-table chrome: soft mist in light, deep slate in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x12 / 255.0, green: 0x18 / 255.0, blue: 0x16 / 255.0)
            : Color(red: 0xF3 / 255.0, green: 0xF6 / 255.0, blue: 0xF4 / 255.0)
    }

    /// Card surface — sits above the app background (sheets, stats cards).
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1E / 255.0, green: 0x26 / 255.0, blue: 0x23 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x2A / 255.0, green: 0x33 / 255.0, blue: 0x2F / 255.0)
            : Color(red: 0xE7 / 255.0, green: 0xEE / 255.0, blue: 0xEA / 255.0)
    }

    /// Primary text — high contrast in both modes (WCAG AA).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xEC / 255.0, green: 0xF2 / 255.0, blue: 0xEE / 255.0)
            : Color(red: 0x1C / 255.0, green: 0x24 / 255.0, blue: 0x21 / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9D / 255.0, green: 0xAB / 255.0, blue: 0xA4 / 255.0)
            : Color(red: 0x5C / 255.0, green: 0x68 / 255.0, blue: 0x62 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    static func accent(_ scheme: ColorScheme) -> Color { emerald }
}

// MARK: - Felt theme (selectable in Settings)

/// The colored "table" the cards sit on. Three options; two extras gated behind Pro.
enum FeltTheme: String, CaseIterable, Identifiable {
    case emerald = "Emerald"
    case sapphire = "Sapphire"
    case wine = "Wine"

    var id: String { rawValue }

    /// Whether this felt requires Spindle Pro. The default emerald is always free.
    var requiresPro: Bool { self != .emerald }

    /// Top-to-bottom felt gradient colors.
    var feltTop: Color {
        switch self {
        case .emerald: return Color(red: 0x12 / 255.0, green: 0x5C / 255.0, blue: 0x44 / 255.0)
        case .sapphire: return Color(red: 0x16 / 255.0, green: 0x3A / 255.0, blue: 0x66 / 255.0)
        case .wine: return Color(red: 0x5A / 255.0, green: 0x1E / 255.0, blue: 0x32 / 255.0)
        }
    }

    var feltBottom: Color {
        switch self {
        case .emerald: return Color(red: 0x0B / 255.0, green: 0x3C / 255.0, blue: 0x2C / 255.0)
        case .sapphire: return Color(red: 0x0C / 255.0, green: 0x22 / 255.0, blue: 0x40 / 255.0)
        case .wine: return Color(red: 0x39 / 255.0, green: 0x10 / 255.0, blue: 0x1F / 255.0)
        }
    }

    /// Color used for empty-column outlines / pip-hole strokes on this felt.
    var feltStroke: Color { Color.white.opacity(0.16) }

    var feltGradient: LinearGradient {
        LinearGradient(colors: [feltTop, feltBottom], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Card back style (selectable in Settings)

enum CardBackStyle: String, CaseIterable, Identifiable {
    case lattice = "Lattice"
    case waves = "Waves"
    case solid = "Solid"
    var id: String { rawValue }
}

// MARK: - Card container (chrome surfaces)

/// A rounded, tactile surface used on non-table screens.
struct SpindleCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpindleTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(SpindleTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

/// Standard screen background for chrome screens (Stats, How to Play, Settings).
struct SpindleBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        SpindleTheme.appBackground(scheme).ignoresSafeArea()
    }
}

// MARK: - Primary button style

struct SpindlePrimaryButtonStyle: ButtonStyle {
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
                          ? (configuration.isPressed ? SpindleTheme.emeraldDeep : SpindleTheme.emerald)
                          : SpindleTheme.emerald.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (outline) button style

struct SpindleSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(SpindleTheme.emeraldDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SpindleTheme.emerald.opacity(configuration.isPressed ? 0.26 : 0.14))
            )
    }
}

// MARK: - Chip style

struct SpindleChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : SpindleTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? SpindleTheme.emerald : SpindleTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func spindleChip(selected: Bool) -> some View { modifier(SpindleChip(selected: selected)) }
}
