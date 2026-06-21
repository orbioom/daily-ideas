import SwiftUI

enum CardSize {
    case small, medium, large

    var width: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 52
        case .large: return 80
        }
    }

    var height: CGFloat {
        switch self {
        case .small: return 88
        case .medium: return 72
        case .large: return 112
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 7
        case .large: return 12
        }
    }

    /// Font size in points for the rank/suit labels in the card corners.
    var rankFontSize: CGFloat {
        switch self {
        case .small: return 13
        case .medium: return 12
        case .large: return 18
        }
    }

    /// Font size in points for the large center suit symbol.
    var centerFontSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 20
        case .large: return 36
        }
    }

    var rankFont: Font {
        .system(size: rankFontSize, weight: .bold)
    }

    var centerFont: Font {
        .system(size: centerFontSize)
    }
}

struct CardView: View {
    let card: Card
    let size: CardSize
    let faceDown: Bool

    private var suitColor: Color {
        card.suit.color == "red" ? Color(red: 0.85, green: 0.10, blue: 0.10) : .black
    }

    var body: some View {
        ZStack {
            if faceDown {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.25, blue: 0.65),
                                Color(red: 0.10, green: 0.15, blue: 0.50)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        // Decorative pattern on card back
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: size.centerFontSize * 0.9))
                            .foregroundStyle(Color.white.opacity(0.15))
                    )
            } else {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(Color.white)
                    .frame(width: size.width, height: size.height)
                    .shadow(color: BuckTheme.cardShadow, radius: 4, y: 2)
                    .overlay(
                        ZStack {
                            // Top-left rank + suit label
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    VStack(alignment: .leading, spacing: -2) {
                                        Text(card.rank.display)
                                            .font(size.rankFont)
                                            .foregroundStyle(suitColor)
                                        Text(card.suit.rawValue)
                                            .font(.system(size: size.rankFontSize - 1))
                                            .foregroundStyle(suitColor)
                                    }
                                    Spacer()
                                }
                                Spacer()
                                // Bottom-right rank + suit label (rotated 180°)
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: -2) {
                                        Text(card.suit.rawValue)
                                            .font(.system(size: size.rankFontSize - 1))
                                            .foregroundStyle(suitColor)
                                        Text(card.rank.display)
                                            .font(size.rankFont)
                                            .foregroundStyle(suitColor)
                                    }
                                    .rotationEffect(.degrees(180))
                                }
                            }
                            .padding(5)

                            // Large center suit symbol
                            Text(card.suit.rawValue)
                                .font(size.centerFont)
                                .foregroundStyle(suitColor)
                        }
                        .frame(width: size.width, height: size.height)
                    )
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
