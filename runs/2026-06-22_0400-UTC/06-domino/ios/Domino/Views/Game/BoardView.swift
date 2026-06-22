import SwiftUI

struct BoardView: View {
    let chain: [DominoEngine.PlacedTile]
    let leftEnd: Int
    let rightEnd: Int
    let tileStyle: DominoTheme.TileStyle

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: DominoTheme.boardSpacing) {
                    if chain.isEmpty {
                        emptyChainPlaceholder
                    } else {
                        ForEach(Array(chain.enumerated()), id: \.element.id) { index, placed in
                            let isFirst = index == 0
                            let isLast = index == chain.count - 1
                            TileView(
                                placed: placed,
                                isHighlighted: isFirst || isLast,
                                tileStyle: tileStyle
                            )
                            .id(placed.id)

                            if index < chain.count - 1 {
                                // Connector line between tiles
                                Rectangle()
                                    .fill(DominoTheme.gold.opacity(0.4))
                                    .frame(width: 2, height: 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: chain.count) { _, _ in
                if let last = chain.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DominoTheme.mahoganyDark.opacity(0.6))
        )
    }

    private var emptyChainPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 32))
                .foregroundStyle(DominoTheme.gold.opacity(0.5))
            Text("Play your first tile")
                .font(DominoTheme.captionFont)
                .foregroundStyle(DominoTheme.gold.opacity(0.6))
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Empty board — play your first tile")
    }
}

// MARK: - Open End Indicator

struct OpenEndBadge: View {
    let pipValue: Int
    let side: String  // "L" or "R"

    var body: some View {
        HStack(spacing: 4) {
            if side == "R" {
                Text(side)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DominoTheme.chainHighlight)
                PipView(value: pipValue, pipColor: DominoTheme.chainHighlight, size: 20)
            } else {
                PipView(value: pipValue, pipColor: DominoTheme.chainHighlight, size: 20)
                Text(side)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DominoTheme.chainHighlight)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(DominoTheme.chainHighlight.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(DominoTheme.chainHighlight.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

#Preview {
    let engine = DominoEngine()
    BoardView(
        chain: [],
        leftEnd: 0,
        rightEnd: 0,
        tileStyle: .classic
    )
    .padding()
    .background(DominoTheme.mahogany)
}
