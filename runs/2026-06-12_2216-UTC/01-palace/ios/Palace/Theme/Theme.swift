import SwiftUI

/// Palace design language: a quiet members' card room.
/// Deep felt surfaces, ivory cards, brass-gold accents, serif numerals.
enum Felt: String, CaseIterable, Identifiable {
    case classic, midnight, burgundy

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .classic: return "Classic Green"
        case .midnight: return "Midnight"
        case .burgundy: return "Burgundy"
        }
    }

    func colors(for scheme: ColorScheme) -> (top: Color, bottom: Color) {
        let dark = scheme == .dark
        switch self {
        case .classic:
            return dark
                ? (Color(red: 0.05, green: 0.20, blue: 0.14), Color(red: 0.02, green: 0.11, blue: 0.08))
                : (Color(red: 0.11, green: 0.36, blue: 0.25), Color(red: 0.06, green: 0.25, blue: 0.17))
        case .midnight:
            return dark
                ? (Color(red: 0.08, green: 0.10, blue: 0.22), Color(red: 0.04, green: 0.05, blue: 0.12))
                : (Color(red: 0.14, green: 0.18, blue: 0.36), Color(red: 0.08, green: 0.11, blue: 0.25))
        case .burgundy:
            return dark
                ? (Color(red: 0.21, green: 0.07, blue: 0.10), Color(red: 0.11, green: 0.03, blue: 0.05))
                : (Color(red: 0.36, green: 0.12, blue: 0.16), Color(red: 0.24, green: 0.07, blue: 0.10))
        }
    }
}

enum PalaceTheme {
    static let gold = Color(red: 0.84, green: 0.70, blue: 0.37)
    static let cardFace = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let cardInk = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let cardRed = Color(red: 0.76, green: 0.18, blue: 0.16)

    static func feltBackground(_ felt: Felt, scheme: ColorScheme) -> LinearGradient {
        let c = felt.colors(for: scheme)
        return LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
    }
}

extension View {
    /// Standard content card used on non-game screens.
    func palacePanel() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
                .foregroundStyle(.primary)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .palacePanel()
        .accessibilityElement(children: .combine)
    }
}
