import SwiftUI

/// Compact metric tile used on summary cards and insights.
struct StatTile: View {
    let value: String
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle.map { "\(value), \($0)" } ?? value)
    }
}
