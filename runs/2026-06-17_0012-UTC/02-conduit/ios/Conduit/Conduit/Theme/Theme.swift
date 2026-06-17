import SwiftUI

/// Conduit design language: a clean modern connect-puzzle look.
/// Deep navy board, crisp surfaces, and a confident blue accent (#3D7BF7).
/// First-class in both light and dark mode via adaptive helpers.
enum ConduitTheme {

    // MARK: - Brand colors

    /// Primary blue accent — mirrors the asset-catalog AccentColor.
    static let accent = Color(red: 0x3D / 255.0, green: 0x7B / 255.0, blue: 0xF7 / 255.0)
    /// A deeper blue for pressed / emphasis states.
    static let accentDeep = Color(red: 0x2A / 255.0, green: 0x5C / 255.0, blue: 0xCC / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: soft off-white in light, deep navy-black in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x0B / 255.0, green: 0x0F / 255.0, blue: 0x1A / 255.0)
            : Color(red: 0xF4 / 255.0, green: 0xF6 / 255.0, blue: 0xFB / 255.0)
    }

    /// Card surface sitting above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x15 / 255.0, green: 0x1B / 255.0, blue: 0x2B / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1E / 255.0, green: 0x26 / 255.0, blue: 0x3A / 255.0)
            : Color(red: 0xE9 / 255.0, green: 0xED / 255.0, blue: 0xF6 / 255.0)
    }

    /// The puzzle board itself — always a deep navy so pipe colors pop.
    static func boardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x10 / 255.0, green: 0x16 / 255.0, blue: 0x26 / 255.0)
            : Color(red: 0x1A / 255.0, green: 0x22 / 255.0, blue: 0x38 / 255.0)
    }

    /// Grid cell fill on the board.
    static func cellSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x18 / 255.0, green: 0x20 / 255.0, blue: 0x33 / 255.0)
            : Color(red: 0x23 / 255.0, green: 0x2D / 255.0, blue: 0x47 / 255.0)
    }

    /// Grid line color drawn between cells.
    static let gridLine = Color.white.opacity(0.10)
    static let gridLineStrong = Color.white.opacity(0.20)

    /// Primary text — high contrast in both modes (WCAG AA).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xEE / 255.0, green: 0xF2 / 255.0, blue: 0xFA / 255.0)
            : Color(red: 0x16 / 255.0, green: 0x1C / 255.0, blue: 0x2B / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9A / 255.0, green: 0xA6 / 255.0, blue: 0xBE / 255.0)
            : Color(red: 0x5C / 255.0, green: 0x66 / 255.0, blue: 0x7E / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }
}

// MARK: - Pipe palette

/// The vivid, distinct colors used for pipe pairs.
/// Indexed by `PipeColor`; the optional color-blind variant adds a letter label.
enum PipeColor: Int, CaseIterable, Codable, Identifiable, Sendable {
    case red = 0
    case green
    case blue
    case yellow
    case orange
    case cyan
    case magenta
    case lime
    case purple
    case pink
    case teal
    case amber

    var id: Int { rawValue }

    /// A vivid, well-separated swatch readable on the navy board.
    var color: Color {
        switch self {
        case .red:     return Color(red: 0xFF / 255.0, green: 0x45 / 255.0, blue: 0x45 / 255.0)
        case .green:   return Color(red: 0x36 / 255.0, green: 0xD3 / 255.0, blue: 0x6B / 255.0)
        case .blue:    return Color(red: 0x3D / 255.0, green: 0x7B / 255.0, blue: 0xF7 / 255.0)
        case .yellow:  return Color(red: 0xFF / 255.0, green: 0xE0 / 255.0, blue: 0x3B / 255.0)
        case .orange:  return Color(red: 0xFF / 255.0, green: 0x8A / 255.0, blue: 0x33 / 255.0)
        case .cyan:    return Color(red: 0x2D / 255.0, green: 0xD4 / 255.0, blue: 0xD4 / 255.0)
        case .magenta: return Color(red: 0xE0 / 255.0, green: 0x4D / 255.0, blue: 0xD0 / 255.0)
        case .lime:    return Color(red: 0xB4 / 255.0, green: 0xEC / 255.0, blue: 0x36 / 255.0)
        case .purple:  return Color(red: 0x9B / 255.0, green: 0x5C / 255.0, blue: 0xF6 / 255.0)
        case .pink:    return Color(red: 0xFF / 255.0, green: 0x7A / 255.0, blue: 0xA8 / 255.0)
        case .teal:    return Color(red: 0x2C / 255.0, green: 0xBB / 255.0, blue: 0x9E / 255.0)
        case .amber:   return Color(red: 0xD8 / 255.0, green: 0xA8 / 255.0, blue: 0x4A / 255.0)
        }
    }

    /// Short label used in color-blind mode and for accessibility.
    var label: String {
        switch self {
        case .red:     return "R"
        case .green:   return "G"
        case .blue:    return "B"
        case .yellow:  return "Y"
        case .orange:  return "O"
        case .cyan:    return "C"
        case .magenta: return "M"
        case .lime:    return "L"
        case .purple:  return "P"
        case .pink:    return "K"
        case .teal:    return "T"
        case .amber:   return "A"
        }
    }

    /// Spoken color name for VoiceOver.
    var name: String {
        switch self {
        case .red:     return "Red"
        case .green:   return "Green"
        case .blue:    return "Blue"
        case .yellow:  return "Yellow"
        case .orange:  return "Orange"
        case .cyan:    return "Cyan"
        case .magenta: return "Magenta"
        case .lime:    return "Lime"
        case .purple:  return "Purple"
        case .pink:    return "Pink"
        case .teal:    return "Teal"
        case .amber:   return "Amber"
        }
    }
}

// MARK: - Card container

/// A rounded, tactile card surface used across the app.
struct ConduitCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ConduitTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ConduitTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct ConduitPrimaryButtonStyle: ButtonStyle {
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
                          ? (configuration.isPressed ? ConduitTheme.accentDeep : ConduitTheme.accent)
                          : ConduitTheme.accent.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary button style

struct ConduitSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(ConduitTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ConduitTheme.accent.opacity(configuration.isPressed ? 0.26 : 0.14))
            )
    }
}

// MARK: - Chip style modifier

struct ConduitChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : ConduitTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? ConduitTheme.accent : ConduitTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func conduitChip(selected: Bool) -> some View { modifier(ConduitChip(selected: selected)) }
}
