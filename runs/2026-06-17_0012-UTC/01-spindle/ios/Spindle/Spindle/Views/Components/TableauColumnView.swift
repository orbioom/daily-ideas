import SwiftUI

/// One of the ten tableau columns: cards overlapped vertically with a larger
/// gap between face-up cards so ranks stay readable.
struct TableauColumnView: View {
    let columnIndex: Int
    let cards: [Card]
    let cardWidth: CGFloat
    let backStyle: CardBackStyle
    let feltStroke: Color
    /// Index of the hinted card in this column, if the active hint targets it.
    var hintedIndex: Int?
    /// Returns true if the card at this index is selected.
    let isSelected: (Int) -> Bool
    /// Tap handler with the tapped card index (nil = the empty-column drop target).
    let onTap: (Int?) -> Void
    let onDoubleTap: (Int?) -> Void

    private var faceUpGap: CGFloat { cardWidth * 0.34 }
    private var faceDownGap: CGFloat { cardWidth * 0.18 }
    private var cardHeight: CGFloat { cardWidth * 1.44 }

    /// Vertical offsets computed so face-down cards stack tighter than face-up ones.
    private var offsets: [CGFloat] {
        var result: [CGFloat] = []
        var y: CGFloat = 0
        for (i, card) in cards.enumerated() {
            result.append(y)
            if i < cards.count - 1 {
                y += card.faceUp ? faceUpGap : faceDownGap
            }
        }
        return result
    }

    private var totalHeight: CGFloat {
        (offsets.last ?? 0) + cardHeight
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Empty-column drop target.
            RoundedRectangle(cornerRadius: cardWidth * 0.13, style: .continuous)
                .strokeBorder(feltStroke, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .frame(width: cardWidth, height: cardHeight)
                .overlay {
                    if cards.isEmpty {
                        Image(systemName: "suit.spade")
                            .font(.system(size: cardWidth * 0.3))
                            .foregroundStyle(feltStroke)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { onTap(nil) }

            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                cardLayer(index: index, card: card)
            }
        }
        .frame(width: cardWidth, height: max(cardHeight, totalHeight), alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Column \(columnIndex + 1), \(cards.count) cards")
    }

    /// One card layer: the full card visual plus a top-anchored hit strip sized to
    /// the card's visible region, so taps on overlapped cards reach the right card.
    @ViewBuilder
    private func cardLayer(index: Int, card: Card) -> some View {
        let isLast = index == cards.count - 1
        let strip = isLast ? cardHeight : (card.faceUp ? faceUpGap : faceDownGap)
        ZStack(alignment: .top) {
            CardView(
                card: card,
                width: cardWidth,
                selected: isSelected(index),
                hinted: hintedIndex == index,
                backStyle: backStyle
            )
            // Transparent hit strip covering only the visible portion of this card.
            Rectangle()
                .fill(Color.white.opacity(0.0001))
                .frame(width: cardWidth, height: max(8, strip))
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { onDoubleTap(index) }
                .onTapGesture { onTap(index) }
        }
        .frame(width: cardWidth, height: cardHeight, alignment: .top)
        .offset(y: offsets[safe: index] ?? 0)
        .zIndex(Double(index))
        .accessibilityElement()
        .accessibilityLabel(cardLabel(card))
        .accessibilityHint(card.faceUp ? "Double tap to auto-move, or tap to select." : "Face down.")
        .accessibilityAddTraits(isSelected(index) ? .isSelected : [])
    }

    private func cardLabel(_ card: Card) -> String {
        card.faceUp ? card.spokenName : "Face-down card"
    }
}
