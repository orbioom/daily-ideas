import SwiftUI

/// A serif quotation card with a save (favourite) toggle. Used as the Today
/// hero and inside the Library list.
struct QuoteCard: View {
    let quote: StoicQuote
    var isSaved: Bool
    var large: Bool = false
    var onToggleSave: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Pill(text: quote.theme.rawValue)
                    Spacer()
                    Button {
                        Haptics.tap()
                        onToggleSave()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
                            .foregroundStyle(isSaved ? Theme.accent : Theme.inkFaint)
                    }
                    .accessibilityLabel(isSaved ? "Remove from favourites" : "Save to favourites")
                }

                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(Theme.serif(large ? 26 : 20, .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.author)
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.accent)
                    Text(quote.source)
                        .font(Theme.rounded(13, .regular))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quote by \(quote.author): \(quote.text). \(isSaved ? "Saved." : "")")
    }
}

/// A compact virtue chip / badge.
struct VirtueBadge: View {
    let virtue: Virtue
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: virtue.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(virtue.tint)
            Text(virtue.rawValue)
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(virtue.tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Virtue: \(virtue.rawValue)")
    }
}
