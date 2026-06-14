import SwiftUI

/// A vinyl-cover card for the collection grid.
struct RecordCard: View {
    let record: Record
    var hideValue: Bool = false
    var moneyText: (Double) -> String = { String(format: "$%.0f", $0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(title: record.title, artist: record.artist, hue: record.coverHue)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(record.artist)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Pill(text: record.format.display, systemImage: record.format.symbol, tint: Theme.accent)
                    Text(record.yearLabel)
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkFaint)
                    Spacer(minLength: 0)
                    if !hideValue && record.estValue > 0 {
                        Text(moneyText(record.estValue))
                            .font(Theme.rounded(12, .bold))
                            .foregroundStyle(Theme.good)
                            .monospacedDigit()
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.title) by \(record.artist), \(record.format.display), \(record.yearLabel)")
    }
}
