import SwiftUI

/// Haven's design language: soft, warm, safe. A gentle lavender/blush identity
/// that adapts cleanly to light and dark while staying WCAG-AA legible.
enum HavenTheme {

    // MARK: - Brand

    /// Soft violet accent (#8A7CD8) — matches the asset-catalog AccentColor.
    static let accent = Color(red: 0x8A / 255, green: 0x7C / 255, blue: 0xD8 / 255)

    /// A deeper violet for text/foreground on light surfaces (AA contrast).
    static let accentDeep = Color(red: 0x5A / 255, green: 0x4C / 255, blue: 0xA8 / 255)

    /// Warm blush used in gradients and highlights.
    static let blush = Color(red: 0xE9 / 255, green: 0xC9 / 255, blue: 0xDA / 255)

    /// Calm sage for "positive / safe" signals (e.g. streaks).
    static let calmGreen = Color(red: 0x4F / 255, green: 0x8A / 255, blue: 0x6E / 255)

    /// Gentle amber for medium intensity.
    static let warmAmber = Color(red: 0xC9 / 255, green: 0x8A / 255, blue: 0x4F / 255)

    /// Soft rose for higher intensity (never harsh red).
    static let softRose = Color(red: 0xC6 / 255, green: 0x6E / 255, blue: 0x7A / 255)

    // MARK: - Adaptive surfaces

    /// Primary page background — adapts to color scheme.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x18 / 255, green: 0x15 / 255, blue: 0x20 / 255)
            : Color(red: 0xFB / 255, green: 0xF7 / 255, blue: 0xFC / 255)
    }

    /// Elevated card surface.
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x24 / 255, green: 0x20 / 255, blue: 0x2E / 255)
            : Color.white
    }

    /// Subtle fill for chips, tiles, secondary buttons.
    static func subtleFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x2E / 255, green: 0x29 / 255, blue: 0x3A / 255)
            : Color(red: 0xF1 / 255, green: 0xEC / 255, blue: 0xF8 / 255)
    }

    /// Primary text color (AA on both schemes).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF2 / 255, green: 0xEF / 255, blue: 0xF7 / 255)
            : Color(red: 0x2A / 255, green: 0x25 / 255, blue: 0x36 / 255)
    }

    /// Secondary / muted text (still AA at ~4.6:1).
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xB6 / 255, green: 0xAE / 255, blue: 0xC6 / 255)
            : Color(red: 0x60 / 255, green: 0x58 / 255, blue: 0x74 / 255)
    }

    // MARK: - Gradients

    /// The signature soft blush→lavender backdrop.
    static func ambientGradient(_ scheme: ColorScheme) -> LinearGradient {
        let stops: [Color] = scheme == .dark
            ? [Color(red: 0x20 / 255, green: 0x1A / 255, blue: 0x2C / 255),
               Color(red: 0x18 / 255, green: 0x15 / 255, blue: 0x22 / 255),
               Color(red: 0x22 / 255, green: 0x18 / 255, blue: 0x26 / 255)]
            : [Color(red: 0xF6 / 255, green: 0xEC / 255, blue: 0xF8 / 255),
               Color(red: 0xFB / 255, green: 0xF6 / 255, blue: 0xFB / 255),
               Color(red: 0xF9 / 255, green: 0xEF / 255, blue: 0xF1 / 255)]
        return LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Warm accent gradient for the primary SOS action.
    static var sosGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0x9C / 255, green: 0x8E / 255, blue: 0xE0 / 255),
                Color(red: 0x8A / 255, green: 0x7C / 255, blue: 0xD8 / 255),
                Color(red: 0xB9 / 255, green: 0x8F / 255, blue: 0xC2 / 255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// The breathing orb gradient.
    static var orbGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 0xC9 / 255, green: 0xBE / 255, blue: 0xF0 / 255),
                Color(red: 0x9C / 255, green: 0x8E / 255, blue: 0xE0 / 255),
                Color(red: 0x8A / 255, green: 0x7C / 255, blue: 0xD8 / 255)
            ],
            center: .center,
            startRadius: 4,
            endRadius: 180
        )
    }

    // MARK: - Metrics

    static let cornerLarge: CGFloat = 28
    static let cornerMedium: CGFloat = 20
    static let cornerSmall: CGFloat = 14
    static let spacing: CGFloat = 16
}

// MARK: - Reusable surfaces

/// A very rounded, softly shadowed card — the core Haven container.
struct HavenCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenTheme.card(scheme))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.0 : 0.05), radius: 12, x: 0, y: 4)
    }
}

/// Page background that fills the safe area with the ambient gradient.
struct HavenBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        HavenTheme.ambientGradient(scheme).ignoresSafeArea()
    }
}

extension View {
    /// Standard rounded soft-button styling used across calm CTAs.
    func havenPillButton(filled: Bool = true) -> some View {
        modifier(HavenPillButton(filled: filled))
    }
}

private struct HavenPillButton: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var filled: Bool
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(filled ? Color.white : HavenTheme.accentDeep)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if filled {
                        AnyView(HavenTheme.sosGradient)
                    } else {
                        AnyView(HavenTheme.subtleFill(scheme))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerLarge, style: .continuous))
    }
}
