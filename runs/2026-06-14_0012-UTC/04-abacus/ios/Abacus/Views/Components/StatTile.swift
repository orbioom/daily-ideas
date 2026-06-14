import SwiftUI

/// A compact metric tile: caption on top, value below, optional tint + symbol.
struct StatTile: View {
    let caption: String
    let value: String
    var tint: Color = Theme.ink
    var symbol: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
                Text(caption)
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(value)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption)
        .accessibilityValue(value)
    }
}

/// A single label/value row for compact summaries.
struct InfoRow: View {
    let label: String
    let value: String
    var valueTint: Color = Theme.ink

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(valueTint)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
