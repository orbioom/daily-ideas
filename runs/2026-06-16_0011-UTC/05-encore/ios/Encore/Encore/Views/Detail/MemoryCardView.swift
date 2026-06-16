import SwiftUI

/// A shareable square memory card rendered to an image via ImageRenderer.
struct MemoryCardView: View {
    let concert: Concert
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("ENCORE")
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .kerning(2)
                Spacer(minLength: 0)
                Text(concert.headliner)
                    .font(Theme.rounded(34, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                if !concert.tourName.isEmpty {
                    Text(concert.tourName)
                        .font(Theme.rounded(16, .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .frame(height: 230)

            DashedDivider()
                .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 12) {
                detail("Venue", concert.locationLine.isEmpty ? concert.venueName : concert.locationLine)
                detail("Date", concert.date.formatted(date: .long, time: .omitted))
                if let rating = concert.rating {
                    HStack(spacing: 8) {
                        Text("Rating")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(width: 64, alignment: .leading)
                        RatingStarsDisplay(rating: rating, size: 16)
                    }
                }
                if !concert.companions.isEmpty {
                    detail("With", concert.companions)
                }
                if concert.ticketPrice > 0 {
                    detail("Ticket", CurrencyFormatter.string(concert.ticketPrice, code: currencyCode))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 360, height: 480)
        .background(
            ZStack {
                Theme.surface
                Theme.ticketGradient(seed: concert.colorSeed)
                    .frame(height: 230)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
