import SwiftUI

struct CardView: View {
    let card: PlayingCard
    var isSelected: Bool = false
    var isCovered: Bool = false
    var size: CGSize = CGSize(width: 40, height: 56)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var suitColor: Color {
        card.suit.isRed ? ApexTheme.heartRed : .primary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .shadow(color: ApexTheme.cardShadow, radius: 2, x: 1, y: 1)

            if isCovered {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color("CardBack"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .padding(3)
                    )
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text(card.rankLabel)
                            .font(.apexCard())
                            .foregroundStyle(suitColor)
                        Spacer()
                    }
                    .padding(.horizontal, 3)
                    .padding(.top, 2)
                    Spacer()
                    Text(card.suit.rawValue)
                        .font(.system(size: size.width * 0.38))
                        .foregroundStyle(suitColor)
                    Spacer()
                    HStack {
                        Spacer()
                        Text(card.rankLabel)
                            .font(.apexCard())
                            .foregroundStyle(suitColor)
                            .rotationEffect(.degrees(180))
                    }
                    .padding(.horizontal, 3)
                    .padding(.bottom, 2)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? ApexTheme.gold : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.2), value: isSelected)
        .accessibilityLabel("\(card.displayName)\(isCovered ? ", face down" : "")\(isSelected ? ", selected" : "")")
    }
}

struct EmptyCardSlot: View {
    var size: CGSize = CGSize(width: 40, height: 56)

    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
            .frame(width: size.width, height: size.height)
    }
}
