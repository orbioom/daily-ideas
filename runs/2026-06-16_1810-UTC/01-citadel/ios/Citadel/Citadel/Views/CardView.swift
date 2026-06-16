import SwiftUI

/// A single rendered card face — warm ivory with crisp suit pips.
struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    /// Scale factor relative to the base card metrics (driven by available width).
    var width: CGFloat = 64

    private var height: CGFloat { width * 1.4 }
    private var corner: CGFloat { width * 0.14 }

    private var pipColor: Color {
        card.suit.pipColor == .red ? Theme.redPip : Theme.blackPip
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(isSelected ? Theme.cardFaceRaised : Theme.cardFace)
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(
                            isSelected ? Theme.gold : Color.black.opacity(0.10),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                )
                .shadow(color: Color.black.opacity(0.22),
                        radius: isSelected ? 6 : 3,
                        x: 0, y: isSelected ? 4 : 2)

            // Top-left rank + pip
            VStack(alignment: .leading, spacing: 1) {
                Text(card.rankLabel)
                    .font(.system(size: width * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(pipColor)
                Image(systemName: card.suit.symbolName)
                    .font(.system(size: width * 0.22))
                    .foregroundStyle(pipColor)
            }
            .padding(.leading, width * 0.12)
            .padding(.top, width * 0.10)

            // Center pip (decorative, hidden from VoiceOver)
            Image(systemName: card.suit.symbolName)
                .font(.system(size: width * 0.42))
                .foregroundStyle(pipColor.opacity(0.92))
                .frame(width: width, height: height, alignment: .center)
                .accessibilityHidden(true)
        }
        .frame(width: width, height: height)
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.accessibilityName)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}

/// An empty slot (foundation/free cell/empty cascade) rendered as an outlined rectangle.
struct SlotView: View {
    @Environment(\.colorScheme) private var colorScheme

    var width: CGFloat = 64
    var symbol: String? = nil
    var symbolColor: Color = .secondary
    var isHighlighted: Bool = false

    private var height: CGFloat { width * 1.4 }
    private var corner: CGFloat { width * 0.14 }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Theme.slotFill(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? Theme.gold : Theme.slotStroke(for: colorScheme),
                        style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5,
                                           dash: isHighlighted ? [] : [4, 4])
                    )
            )
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: width * 0.42))
                        .foregroundStyle(symbolColor.opacity(0.55))
                        .accessibilityHidden(true)
                }
            }
            .frame(width: width, height: height)
    }
}
