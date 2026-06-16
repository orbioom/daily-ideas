import SwiftUI

/// A compact metric card with a title, value, and optional caption/accent.
struct MetricTile: View {
    let title: String
    let value: String
    var caption: String? = nil
    var systemImage: String? = nil
    var valueColor: Color = Theme.ink
    var accessibilityValueText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let caption {
                Text(caption)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValueText ?? value)
    }
}

/// A larger hero tile for the dashboard, drawn on the accent gradient.
struct HeroTile: View {
    let title: String
    let value: String
    var caption: String? = nil
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .accessibilityHidden(true)
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.9))

            Text(value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(title)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(.white.opacity(0.85))
            if let caption {
                Text(caption)
                    .font(Theme.rounded(11))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
