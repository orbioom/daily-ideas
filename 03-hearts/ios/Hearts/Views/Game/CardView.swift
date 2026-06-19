import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var isFaceDown: Bool = false
    var size: CardSize = .normal

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(isFaceDown ? Color(red: 0.15, green: 0.25, blue: 0.60) : .white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            if isFaceDown {
                RoundedRectangle(cornerRadius: size.cornerRadius - 3)
                    .fill(Color.white.opacity(0.05))
                    .padding(4)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        cardLabel(size: .small)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        cardLabel(size: .small)
                            .rotationEffect(.degrees(180))
                    }
                }
                .padding(size.padding)

                Text(card.suit.symbol)
                    .font(.system(size: size.suitFontSize))
                    .foregroundStyle(card.suit.isRed ? .red : .black)
            }
        }
        .frame(width: size.width, height: size.height)
        .offset(y: isSelected ? -10 : 0)
        .animation(.spring(response: 0.2), value: isSelected)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private func cardLabel(size sizeHint: LabelSize) -> some View {
        VStack(spacing: -2) {
            Text(card.rank.display)
                .font(.system(size: self.size.rankFontSize, weight: .bold))
                .foregroundStyle(card.suit.isRed ? .red : .black)
            Text(card.suit.symbol)
                .font(.system(size: self.size.suitSmallFontSize))
                .foregroundStyle(card.suit.isRed ? .red : .black)
        }
    }

    private enum LabelSize { case small }
}

enum CardSize {
    case tiny, small, normal, large

    var width: CGFloat {
        switch self { case .tiny: return 32; case .small: return 44; case .normal: return 64; case .large: return 80 }
    }
    var height: CGFloat { width * 1.4 }
    var cornerRadius: CGFloat { width * 0.12 }
    var rankFontSize: CGFloat { width * 0.22 }
    var suitFontSize: CGFloat { width * 0.45 }
    var suitSmallFontSize: CGFloat { width * 0.15 }
    var padding: CGFloat { width * 0.08 }
}
