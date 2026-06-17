import SwiftUI

/// The row above the tableau: 8 foundation slots on the left, the stock pile
/// (tappable to deal) on the right.
struct BoardTopRow: View {
    let foundations: [Suit]
    let dealsRemaining: Int
    let canDeal: Bool
    let cardWidth: CGFloat
    let backStyle: CardBackStyle
    let feltStroke: Color
    let onDeal: () -> Void

    private var slotWidth: CGFloat { cardWidth * 0.82 }
    private var slotHeight: CGFloat { slotWidth * 1.44 }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            foundationsView
            Spacer(minLength: 6)
            stockView
        }
    }

    // MARK: Foundations

    private var foundationsView: some View {
        HStack(spacing: slotWidth * 0.12) {
            ForEach(0..<SpiderEngine.foundationGoal, id: \.self) { i in
                foundationSlot(at: i)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Foundations: \(foundations.count) of 8 complete runs collected")
    }

    @ViewBuilder
    private func foundationSlot(at i: Int) -> some View {
        let suit = foundations[safe: i]
        ZStack {
            RoundedRectangle(cornerRadius: slotWidth * 0.13, style: .continuous)
                .strokeBorder(feltStroke, lineWidth: 1.2)
                .background(
                    RoundedRectangle(cornerRadius: slotWidth * 0.13, style: .continuous)
                        .fill(suit == nil ? Color.white.opacity(0.04) : Color.black.opacity(0.18))
                )
            if let suit {
                Text(suit.symbol)
                    .font(.system(size: slotWidth * 0.5, weight: .bold))
                    .foregroundStyle(suit.isRed ? Color(red: 0.92, green: 0.42, blue: 0.45) : Color.white.opacity(0.9))
            } else {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: slotWidth * 0.34))
                    .foregroundStyle(feltStroke)
            }
        }
        .frame(width: slotWidth, height: slotHeight)
        .accessibilityHidden(true)
    }

    // MARK: Stock

    private var stockView: some View {
        Button(action: onDeal) {
            ZStack {
                // Render a small fan to imply remaining deals.
                let shown = min(3, max(dealsRemaining, canDeal ? 1 : 0))
                if shown == 0 {
                    RoundedRectangle(cornerRadius: cardWidth * 0.13, style: .continuous)
                        .strokeBorder(feltStroke, lineWidth: 1.4)
                        .frame(width: cardWidth, height: cardWidth * 1.44)
                } else {
                    ForEach(0..<shown, id: \.self) { i in
                        CardBackView(backStyle: backStyle, width: cardWidth)
                            .offset(x: CGFloat(i) * 3, y: CGFloat(i) * -2)
                    }
                }
                Text("\(dealsRemaining)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(SpindleTheme.emeraldDeep))
                    .offset(x: cardWidth * 0.34, y: cardWidth * 0.5)
            }
            .frame(width: cardWidth + 12, height: cardWidth * 1.44, alignment: .topLeading)
            .opacity(canDeal ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!canDeal)
        .accessibilityLabel("Stock, \(dealsRemaining) deals remaining")
        .accessibilityHint(canDeal ? "Deals one card to every column." : "Fill every empty column before dealing.")
    }
}
