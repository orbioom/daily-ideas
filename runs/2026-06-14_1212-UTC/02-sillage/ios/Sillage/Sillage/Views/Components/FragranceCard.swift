import SwiftUI

/// Grid card: juice swatch, house, name, concentration badge, rating.
struct FragranceCard: View {
    let fragrance: Fragrance
    var costPerWear: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            JuiceSwatch(family: fragrance.primaryFamily,
                        colorHue: fragrance.colorHue,
                        size: 92)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 3) {
                Text(fragrance.house.uppercased())
                    .font(Theme.rounded(10, .bold))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
                Text(fragrance.name)
                    .font(Theme.serif(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                Text(fragrance.concentration.rawValue)
                    .font(Theme.rounded(10, .bold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accentSoft))
                Spacer()
                if fragrance.rating > 0 {
                    RatingStars(rating: fragrance.rating, size: 9)
                }
            }

            if let costPerWear {
                Text(costPerWear)
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(fragrance.name) by \(fragrance.house), \(fragrance.concentration.fullName)\(fragrance.rating > 0 ? ", rated \(fragrance.rating) of 5" : "")")
    }
}
