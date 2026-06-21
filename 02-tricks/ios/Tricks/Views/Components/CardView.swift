import SwiftUI

struct CardView: View {
    let card: Card
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.white)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            if isHighlighted {
                RoundedRectangle(cornerRadius: 6).stroke(TricksTheme.accent, lineWidth: 2)
            }
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(card.rank.symbol).font(.caption2.bold()).foregroundStyle(card.suit.isRed ? .red : .black)
                        Text(card.suit.symbol).font(.caption2).foregroundStyle(card.suit.isRed ? .red : .black)
                    }
                    Spacer()
                }
                Spacer()
                Text(card.suit.symbol).font(.caption).foregroundStyle(card.suit.isRed ? .red : .black)
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(card.rank.symbol).font(.caption2.bold()).foregroundStyle(card.suit.isRed ? .red : .black)
                        Text(card.suit.symbol).font(.caption2).foregroundStyle(card.suit.isRed ? .red : .black)
                    }.rotationEffect(.degrees(180))
                }
            }.padding(3)
        }
    }
}
