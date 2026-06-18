import SwiftUI

/// A single playing-card face. Sized by its parent via `frame`.
struct CardView: View {
    let card: Card
    var faceUp: Bool = true
    var playable: Bool = false
    var hinted: Bool = false
    var dimmed: Bool = false

    @ScaledMetric(relativeTo: .body) private var cornerLabelSize: CGFloat = 13

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .fill(faceUp ? AnyShapeStyle(Theme.cardFace) : AnyShapeStyle(cardBack))
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: hinted ? 2.5 : 1)

                if faceUp {
                    faceContent(width: w)
                } else {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: w * 0.34))
                        .foregroundStyle(Color.white.opacity(0.22))
                        .accessibilityHidden(true)
                }
            }
            .shadow(color: .black.opacity(playable ? 0.22 : 0.12),
                    radius: playable ? 5 : 2, x: 0, y: playable ? 3 : 1)
            .opacity(dimmed ? 0.55 : 1)
        }
        .aspectRatio(0.7, contentMode: .fit)
    }

    private var cardBack: LinearGradient {
        LinearGradient(colors: [Theme.cardBack1, Theme.cardBack2],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var borderColor: Color {
        if hinted { return Theme.gold }
        if playable { return Theme.accent.opacity(0.65) }
        return Theme.hairline
    }

    @ViewBuilder
    private func faceContent(width w: CGFloat) -> some View {
        let color = card.suit.color
        VStack {
            HStack {
                cornerStack(color: color)
                Spacer()
            }
            Spacer()
            Image(systemName: suitSymbolName)
                .font(.system(size: w * 0.42, weight: .regular))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Spacer()
            HStack {
                Spacer()
                cornerStack(color: color)
                    .rotationEffect(.degrees(180))
            }
        }
        .padding(w * 0.10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.accessibilityName)
    }

    private func cornerStack(color: Color) -> some View {
        VStack(spacing: 0) {
            Text(card.rankLabel)
                .font(.system(size: cornerLabelSize, weight: .bold, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: cornerLabelSize * 0.85))
        }
        .foregroundStyle(color)
        .minimumScaleFactor(0.5)
    }

    private var suitSymbolName: String {
        switch card.suit {
        case .spades: return "suit.spade.fill"
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        }
    }
}
