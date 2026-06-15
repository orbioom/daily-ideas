import SwiftUI

/// A compact labeled stat tile (icon + value + caption) used on headers and Insights.
struct StatTile: View {
    let label: String
    let value: String
    let icon: String
    var tint: Color = Theme.accent
    var hidden: Bool = false

    var body: some View {
        CardView(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(hidden ? "••••" : value)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(label)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(hidden ? "hidden" : value)")
    }
}

/// A small rounded pill (e.g. sector tag, frequency tag).
struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var color: Color = Theme.accent

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

/// A left-aligned section header for cards.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
