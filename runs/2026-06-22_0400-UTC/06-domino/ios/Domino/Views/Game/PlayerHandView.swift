import SwiftUI

struct PlayerHandView: View {
    let hand: [DominoTile]
    let validMoves: [(tile: DominoTile, end: DominoEngine.ChainEnd)]
    let selectedTile: DominoTile?
    let tileStyle: DominoTheme.TileStyle
    let onSelectTile: (DominoTile) -> Void

    private func isValid(_ tile: DominoTile) -> Bool {
        validMoves.contains { $0.tile == tile }
    }

    var body: some View {
        VStack(spacing: 6) {
            if hand.isEmpty {
                Text("No tiles in hand")
                    .font(DominoTheme.captionFont)
                    .foregroundStyle(DominoTheme.gold.opacity(0.6))
                    .frame(height: 90)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(hand) { tile in
                            let valid = isValid(tile)
                            let isSelected = selectedTile == tile

                            TileView(tile: tile, isSelected: isSelected, tileStyle: tileStyle)
                                .opacity(valid ? 1.0 : 0.45)
                                .scaleEffect(isSelected ? 1.08 : 1.0)
                                .offset(y: isSelected ? -6 : 0)
                                .animation(.spring(response: 0.2), value: isSelected)
                                .onTapGesture {
                                    if valid {
                                        onSelectTile(tile)
                                    }
                                }
                                .overlay {
                                    if !valid {
                                        RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                                            .fill(Color.black.opacity(0.1))
                                    }
                                }
                                .accessibilityLabel("\(tile.a)-\(tile.b) tile\(valid ? ", playable" : ", not playable")")
                                .accessibilityAddTraits(valid ? .isButton : [])
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            // Pip count
            Text("\(hand.count) tile\(hand.count == 1 ? "" : "s") • \(hand.reduce(0) { $0 + $1.totalPips }) pips")
                .font(DominoTheme.captionFont)
                .foregroundStyle(DominoTheme.gold.opacity(0.7))
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DominoTheme.mahoganyDark.opacity(0.5))
        )
    }
}

// MARK: - AI Hand View (face-down)

struct AIHandView: View {
    let count: Int
    let pipTotal: Int
    let showAIHand: Bool
    let hand: [DominoTile]
    let tileStyle: DominoTheme.TileStyle

    var body: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<count, id: \.self) { i in
                        if showAIHand && i < hand.count {
                            TileView(tile: hand[i], tileStyle: tileStyle)
                                .scaleEffect(0.7)
                        } else {
                            TileView(tile: DominoTile(a: 0, b: 0), isFaceDown: true, tileStyle: tileStyle)
                                .scaleEffect(0.7)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Text("AI: \(count) tile\(count == 1 ? "" : "s")\(showAIHand ? " • \(pipTotal) pips" : "")")
                .font(DominoTheme.captionFont)
                .foregroundStyle(DominoTheme.gold.opacity(0.7))
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DominoTheme.mahoganyDark.opacity(0.4))
        )
        .accessibilityLabel("AI has \(count) tiles")
    }
}
