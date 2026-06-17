import SwiftUI

/// Lexicon design language: warm paper, rounded letter tiles, calm rounded type,
/// a tactile tile-flip feel. Wordle-green accent (#6AAA64). Cohesive across every
/// screen. Light and dark are both first-class. A colorblind-friendly high-contrast
/// palette (orange / blue) is available as a Settings toggle.
enum LexTheme {

    // MARK: - Brand accent

    /// Wordle-green accent — also defined in the asset catalog as AccentColor (#6AAA64).
    static let green = Color(red: 0x6A / 255.0, green: 0xAA / 255.0, blue: 0x64 / 255.0)
    static let greenDeep = Color(red: 0x53 / 255.0, green: 0x8D / 255.0, blue: 0x4E / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: warm paper in light, deep charcoal in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x12 / 255.0, green: 0x13 / 255.0, blue: 0x14 / 255.0)
            : Color(red: 0xF7 / 255.0, green: 0xF4 / 255.0, blue: 0xEC / 255.0)
    }

    /// Raised card surface (sheets, stats cards, end cards).
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1D / 255.0, green: 0x1E / 255.0, blue: 0x20 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF8 / 255.0)
    }

    /// Subtle raised surface for chips / fields / keyboard keys at rest.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x33 / 255.0, green: 0x35 / 255.0, blue: 0x39 / 255.0)
            : Color(red: 0xE6 / 255.0, green: 0xE1 / 255.0, blue: 0xD4 / 255.0)
    }

    /// Empty tile border / unfilled tile outline.
    static func tileEmptyBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x3A / 255.0, green: 0x3C / 255.0, blue: 0x40 / 255.0)
            : Color(red: 0xCD / 255.0, green: 0xC7 / 255.0, blue: 0xB8 / 255.0)
    }

    /// Filled-but-unsubmitted tile border (a typed letter awaiting submit).
    static func tileFilledBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x57 / 255.0, green: 0x5A / 255.0, blue: 0x5E / 255.0)
            : Color(red: 0x8C / 255.0, green: 0x86 / 255.0, blue: 0x77 / 255.0)
    }

    /// Primary text — high contrast in both modes (WCAG AA).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF2 / 255.0, green: 0xF0 / 255.0, blue: 0xEA / 255.0)
            : Color(red: 0x20 / 255.0, green: 0x1F / 255.0, blue: 0x1B / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xA6 / 255.0, green: 0xA4 / 255.0, blue: 0x9C / 255.0)
            : Color(red: 0x63 / 255.0, green: 0x5F / 255.0, blue: 0x55 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    // MARK: - Typography

    /// A calm rounded display font used for big titles & tile letters.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Tile state colors

/// The three evaluated states of a guessed letter, plus the keyboard-only "unused".
enum TileState: Int, Codable, CaseIterable {
    case empty = 0      // no letter typed yet
    case tbd = 1        // typed, not yet submitted
    case absent = 2     // letter not in the word
    case present = 3    // letter in the word, wrong position
    case correct = 4    // letter in the right position

    /// Aggregation precedence for the on-screen keyboard (higher wins).
    var keyboardRank: Int {
        switch self {
        case .correct: return 3
        case .present: return 2
        case .absent: return 1
        default: return 0
        }
    }
}

extension TileState {
    /// Background fill for a settled (submitted) tile, honoring the high-contrast palette.
    func fill(scheme: ColorScheme, highContrast: Bool) -> Color {
        switch self {
        case .empty:
            return Color.clear
        case .tbd:
            return LexTheme.cardSurface(scheme)
        case .absent:
            return scheme == .dark
                ? Color(red: 0x3A / 255.0, green: 0x3C / 255.0, blue: 0x40 / 255.0)
                : Color(red: 0x79 / 255.0, green: 0x7B / 255.0, blue: 0x7E / 255.0)
        case .present:
            if highContrast {
                // Colorblind-friendly: blue for "present".
                return Color(red: 0x42 / 255.0, green: 0x8B / 255.0, blue: 0xCA / 255.0)
            }
            return Color(red: 0xC9 / 255.0, green: 0xB4 / 255.0, blue: 0x58 / 255.0)
        case .correct:
            if highContrast {
                // Colorblind-friendly: orange for "correct".
                return Color(red: 0xE6 / 255.0, green: 0x7E / 255.0, blue: 0x22 / 255.0)
            }
            return LexTheme.green
        }
    }

    /// Text color drawn on a settled tile.
    func textColor(scheme: ColorScheme) -> Color {
        switch self {
        case .empty, .tbd:
            return LexTheme.primaryText(scheme)
        default:
            return .white
        }
    }

    /// VoiceOver phrase describing this state.
    var accessibilityPhrase: String {
        switch self {
        case .empty: return "empty"
        case .tbd: return "entered"
        case .absent: return "not in word"
        case .present: return "wrong spot"
        case .correct: return "correct"
        }
    }
}

// MARK: - Card container

/// A rounded, tactile surface used on chrome screens.
struct LexCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LexTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(LexTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

/// Standard screen background.
struct LexBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        LexTheme.appBackground(scheme).ignoresSafeArea()
    }
}

// MARK: - Buttons

struct LexPrimaryButtonStyle: ButtonStyle {
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
                          ? (configuration.isPressed ? LexTheme.greenDeep : LexTheme.green)
                          : LexTheme.green.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct LexSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(LexTheme.greenDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LexTheme.green.opacity(configuration.isPressed ? 0.26 : 0.14))
            )
    }
}

// MARK: - Chip

struct LexChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : LexTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? LexTheme.green : LexTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func lexChip(selected: Bool) -> some View { modifier(LexChip(selected: selected)) }
}
