import SwiftUI

/// "Concert Wrapped" — a shareable summary card rendered via ImageRenderer.
struct WrappedCardView: View {
    let stats: ConcertStats
    let settings: AppSettings

    /// A loose "hours of live music" estimate: ~2.25h per show.
    private var estimatedHours: Int {
        Int((Double(stats.totalAttended) * 2.25).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MY CONCERT WRAPPED")
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .kerning(2)
                Text("A life in live music")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                wrappedRow("\(stats.totalAttended)", "shows attended")
                wrappedRow("\(stats.distinctArtists)", "different artists")
                wrappedRow("\(stats.distinctCities)", "cities")
                wrappedRow("~\(estimatedHours)h", "of live music")
                if stats.totalSpent > 0 {
                    wrappedRow(settings.money(stats.totalSpent), "on tickets", emphasizeLabel: true)
                }
                if let top = stats.mostSeenArtist {
                    wrappedRow(top.label, "most-seen (\(top.count)×)", emphasizeLabel: true)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Image(systemName: "ticket.fill")
                    .foregroundStyle(.white.opacity(0.9))
                Text("Encore")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(28)
        .frame(width: 360, height: 480, alignment: .topLeading)
        .background(Theme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func wrappedRow(_ value: String, _ label: String, emphasizeLabel: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(value)
                .font(Theme.rounded(emphasizeLabel ? 22 : 30, .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}
