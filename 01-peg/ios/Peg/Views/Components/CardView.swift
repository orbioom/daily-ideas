import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var isFaceDown: Bool = false
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(isFaceDown ? PegTheme.feltGreen : PegTheme.creamCard)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.12)
                        .stroke(isSelected ? PegTheme.goldAccent : Color.gray.opacity(0.3), lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 1, y: 2)

            if isFaceDown {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(PegTheme.feltGreenDark)
            } else {
                VStack(spacing: 1) {
                    Text(card.rank.display)
                        .font(.system(size: size * 0.28, weight: .bold, design: .serif))
                    Text(card.suit.rawValue)
                        .font(.system(size: size * 0.24))
                }
                .foregroundStyle(card.suit.isRed ? PegTheme.cardRed : PegTheme.cardBlack)
            }
        }
        .frame(width: size * 0.7, height: size)
        .offset(y: isSelected ? -8 : 0)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}
