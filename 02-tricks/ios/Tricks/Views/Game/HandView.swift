import SwiftUI

struct HandView: View {
    let cards: [Card]
    let legal: [Card]
    let isHuman: Bool
    let seat: PlayerSeat
    let onPlay: (Card) -> Void

    var body: some View {
        let sorted = cards.sorted { a, b in
            if a.suit == b.suit { return a.rank > b.rank }
            return a.suit.rawValue < b.suit.rawValue
        }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -16) {
                ForEach(sorted) { card in
                    CardView(card: card, isHighlighted: legal.contains(card))
                        .frame(width: 60, height: 90)
                        .onTapGesture { if isHuman { onPlay(card) } }
                        .accessibilityLabel("\(card.rank.symbol) of \(card.suit.name)\(legal.contains(card) ? ", playable" : "")")
                        .accessibilityAddTraits(legal.contains(card) ? .isButton : [])
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
