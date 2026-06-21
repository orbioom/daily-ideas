import SwiftUI

struct CardFaceView: View {
    let cardValue: Int
    let suit: String
    var isDealer: Bool = false

    private var rankString: String {
        switch cardValue {
        case 1: return "A"
        case 10: return "10"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return "\(cardValue)"
        }
    }

    private var suitSymbol: String {
        switch suit {
        case "spade": return "♠"
        case "heart": return "♥"
        case "diamond": return "♦"
        case "club": return "♣"
        default: return suit
        }
    }

    private var suitColor: Color {
        switch suit {
        case "heart", "diamond": return Color(red: 0.80, green: 0.10, blue: 0.10)
        default: return .black
        }
    }

    private var cardSize: CGSize {
        isDealer
            ? CGSize(width: 72, height: 100)
            : CGSize(width: 80, height: 112)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(CountTheme.cardBackground)
                .shadow(color: CountTheme.cardShadow, radius: 6, x: 2, y: 3)

            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: -2) {
                        Text(rankString)
                            .font(.system(size: isDealer ? 14 : 16, weight: .bold, design: .rounded))
                            .foregroundStyle(suitColor)
                        Text(suitSymbol)
                            .font(.system(size: isDealer ? 11 : 12))
                            .foregroundStyle(suitColor)
                    }
                    Spacer()
                }
                .padding(.top, 6)
                .padding(.leading, 8)

                Spacer()

                Text(suitSymbol)
                    .font(.system(size: isDealer ? 34 : 40))
                    .foregroundStyle(suitColor)

                Spacer()

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: -2) {
                        Text(suitSymbol)
                            .font(.system(size: isDealer ? 11 : 12))
                            .foregroundStyle(suitColor)
                        Text(rankString)
                            .font(.system(size: isDealer ? 14 : 16, weight: .bold, design: .rounded))
                            .foregroundStyle(suitColor)
                    }
                    .rotationEffect(.degrees(180))
                }
                .padding(.bottom, 6)
                .padding(.trailing, 8)
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }
}

struct CardBackView: View {
    var isDealer: Bool = false

    private var cardSize: CGSize {
        isDealer
            ? CGSize(width: 72, height: 100)
            : CGSize(width: 80, height: 112)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(CountTheme.cardBackground)
                .shadow(color: CountTheme.cardShadow, radius: 6, x: 2, y: 3)

            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)

            RoundedRectangle(cornerRadius: 7)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.25, blue: 0.60),
                            Color(red: 0.05, green: 0.15, blue: 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(6)

            Image(systemName: "suit.diamond.fill")
                .foregroundStyle(Color.white.opacity(0.3))
                .font(.system(size: isDealer ? 28 : 34))
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }
}

private let cardSuits = ["spade", "heart", "diamond", "club"]

func randomSuit(for value: Int) -> String {
    let index = abs(value * 17 + 3) % 4
    return cardSuits[index]
}
