import SwiftUI

/// A ranked restaurant row: rank number, score chip, cuisine, metadata.
struct RestaurantRow: View {
    let restaurant: Restaurant
    let rankNumber: Int
    let score: Double

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rankNumber)")
                .font(Theme.rounded(15, .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.inkFaint)
                .frame(minWidth: 26, alignment: .trailing)
                .accessibilityLabel("Rank \(rankNumber)")

            CuisineBadge(cuisine: restaurant.cuisine, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(restaurant.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if restaurant.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Favorite")
                    }
                }
                HStack(spacing: 6) {
                    Text(restaurant.cuisine.rawValue)
                    Text("·")
                    Text(restaurant.priceLabel)
                    if !restaurant.city.isEmpty {
                        Text("·")
                        Text(restaurant.city).lineLimit(1)
                    }
                }
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            }

            Spacer(minLength: 6)

            ScoreChip(score: score, sentiment: restaurant.sentiment, size: 44)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(restaurant.name), rank \(rankNumber), \(restaurant.cuisine.rawValue) in \(restaurant.city)")
    }
}
