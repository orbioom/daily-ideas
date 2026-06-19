import SwiftUI

struct CardView: View {
    let card: PlayingCard
    var faceUp: Bool = true
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    var cardBackColor: Color = AnteTheme.cardBack
    var width: CGFloat = 60
    var height: CGFloat = 84

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(faceUp ? Color.white : cardBackColor)
            .overlay(
                Group {
                    if faceUp {
                        cardFace
                    } else {
                        cardBack
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.yellow : (isHighlighted ? Color.green : Color.gray.opacity(0.3)),
                        lineWidth: isSelected || isHighlighted ? 3 : 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 2)
            .frame(width: width, height: height)
    }

    private var cardFace: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(card.rank.displayName)
                        .font(.system(size: fontSize(14), weight: .bold))
                        .foregroundColor(card.suit.isRed ? .red : Color(white: 0.1))
                    Text(card.suit.rawValue)
                        .font(.system(size: fontSize(11)))
                        .foregroundColor(card.suit.isRed ? .red : Color(white: 0.1))
                }
                Spacer()
            }
            Spacer()
            Text(card.suit.rawValue)
                .font(.system(size: fontSize(22)))
                .foregroundColor(card.suit.isRed ? .red : Color(white: 0.1))
            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(card.suit.rawValue)
                        .font(.system(size: fontSize(11)))
                        .rotationEffect(.degrees(180))
                        .foregroundColor(card.suit.isRed ? .red : Color(white: 0.1))
                    Text(card.rank.displayName)
                        .font(.system(size: fontSize(14), weight: .bold))
                        .rotationEffect(.degrees(180))
                        .foregroundColor(card.suit.isRed ? .red : Color(white: 0.1))
                }
            }
        }
        .padding(5)
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .padding(5)
            .overlay(
                Image(systemName: "suit.club.fill")
                    .font(.system(size: fontSize(18)))
                    .foregroundColor(.white.opacity(0.4))
            )
    }

    private func fontSize(_ base: CGFloat) -> CGFloat {
        base * (width / 60)
    }
}

// Smaller compact version for fan display
struct SmallCardView: View {
    let card: PlayingCard
    var faceUp: Bool = false
    var cardBackColor: Color = AnteTheme.cardBack

    var body: some View {
        CardView(card: card, faceUp: faceUp, cardBackColor: cardBackColor, width: 38, height: 54)
    }
}
