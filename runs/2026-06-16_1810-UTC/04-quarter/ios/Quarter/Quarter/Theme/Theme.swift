import SwiftUI

/// Centralized design tokens for Quarter — a confident, trustworthy fintech look.
/// Deep ink surfaces, the teal-green accent, generous spacing, large tabular figures.
enum Theme {

    // MARK: - Colors

    /// Primary brand accent (teal-green #13A07F). Mirrors AccentColor asset.
    static let accent = Color(red: 0x13 / 255, green: 0xA0 / 255, blue: 0x7F / 255)

    /// A slightly deeper variant for gradients / pressed states.
    static let accentDeep = Color(red: 0x0E / 255, green: 0x7C / 255, blue: 0x62 / 255)

    /// App background — adapts to light/dark for first-class support.
    static var background: Color { Color(.systemGroupedBackground) }

    /// Elevated card surface.
    static var surface: Color { Color(.secondarySystemGroupedBackground) }

    /// A deeper "ink" surface used for hero panels.
    static var ink: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.10, blue: 0.12, alpha: 1)
                : UIColor(red: 0.07, green: 0.13, blue: 0.13, alpha: 1)
        })
    }

    static var primaryText: Color { Color(.label) }
    static var secondaryText: Color { Color(.secondaryLabel) }
    static var tertiaryText: Color { Color(.tertiaryLabel) }

    /// Positive (refund / paid).
    static let positive = Color(red: 0x13 / 255, green: 0xA0 / 255, blue: 0x7F / 255)
    /// Caution (amount due / balance owed).
    static let warning = Color(red: 0xD9 / 255, green: 0x7A / 255, blue: 0x1E / 255)
    /// Critical / overdue.
    static let critical = Color(red: 0xC4 / 255, green: 0x3D / 255, blue: 0x3D / 255)

    /// Palette for charts (category slices). Chosen for AA contrast on surfaces.
    static let chartPalette: [Color] = [
        accent,
        Color(red: 0x2E / 255, green: 0x6B / 255, blue: 0xE0 / 255),
        Color(red: 0xD9 / 255, green: 0x7A / 255, blue: 0x1E / 255),
        Color(red: 0x8E / 255, green: 0x5A / 255, blue: 0xD9 / 255),
        Color(red: 0xC4 / 255, green: 0x3D / 255, blue: 0x6E / 255),
        Color(red: 0x2A / 255, green: 0xA8 / 255, blue: 0xB0 / 255),
        Color(red: 0x6B / 255, green: 0x8E / 255, blue: 0x23 / 255)
    ]

    static func chartColor(for index: Int) -> Color {
        guard !chartPalette.isEmpty else { return accent }
        return chartPalette[((index % chartPalette.count) + chartPalette.count) % chartPalette.count]
    }

    // MARK: - Metrics

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 18
        static let chip: CGFloat = 10
        static let hero: CGFloat = 26
    }
}

// MARK: - Reusable card container

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.m
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

extension View {
    func card(padding: CGFloat = Theme.Spacing.m) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
            Spacer()
        }
        .accessibilityAddTraits(.isHeader)
    }
}
