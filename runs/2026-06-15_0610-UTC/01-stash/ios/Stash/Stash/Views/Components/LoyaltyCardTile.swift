import SwiftUI

/// A colored wallet card tile showing the store, a category glyph, and a favorite mark.
/// The tint comes from the card's stored color; foreground text auto-contrasts.
struct LoyaltyCardTile: View {
    let card: LoyaltyCard

    private var tint: Color { Color(hexString: card.colorHex, fallback: Theme.accent) }
    private var fg: Color { tint.readableForeground }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: card.category.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(fg.opacity(0.9))
                    .accessibilityHidden(true)
                Spacer()
                if card.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(fg.opacity(0.95))
                        .accessibilityHidden(true)
                }
            }
            Spacer(minLength: 12)
            Text(card.displayTitle)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(fg)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(card.format.displayName)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(fg.opacity(0.8))
                .padding(.top, 2)
        }
        .padding(14)
        .frame(height: 128, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(
                    LinearGradient(colors: [tint, tint.opacity(0.82)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.displayTitle), \(card.category.displayName)\(card.isFavorite ? ", favorite" : "")")
        .accessibilityHint("Opens the card to show its barcode")
    }
}
