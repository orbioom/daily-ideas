import SwiftUI

struct BoardView: View {
    let game: PebbleGame
    let validMoves: [Int]
    let onTap: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // AI row (top): pits 12 down to 7, displayed right-to-left from
            // the player's viewpoint so they face each other.
            aiRow

            // Stores flank the middle area
            HStack(spacing: 8) {
                // Player 1 (AI) store — left side
                PitView(
                    count: game.board.pits[13],
                    isHighlighted: false,
                    isLastMove: false,
                    isValidMove: false,
                    isStore: true,
                    onTap: {}
                )
                .frame(width: 60, height: 110)

                Spacer()

                // Player 0 (human) store — right side
                PitView(
                    count: game.board.pits[6],
                    isHighlighted: false,
                    isLastMove: false,
                    isValidMove: false,
                    isStore: true,
                    onTap: {}
                )
                .frame(width: 60, height: 110)
            }
            .padding(.horizontal, 8)

            // Human row (bottom): pits 0 to 5
            humanRow
        }
        .padding()
        .background(PebbleTheme.woodLight.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var aiRow: some View {
        HStack(spacing: 8) {
            ForEach((7...12).reversed(), id: \.self) { pit in
                PitView(
                    count: game.board.pits[pit],
                    isHighlighted: false,
                    isLastMove: game.lastMove == pit,
                    isValidMove: false,
                    onTap: {}
                )
                .frame(width: 44, height: 54)
                .rotationEffect(.degrees(180))
            }
        }
    }

    private var humanRow: some View {
        HStack(spacing: 8) {
            ForEach(0...5, id: \.self) { pit in
                PitView(
                    count: game.board.pits[pit],
                    isHighlighted: validMoves.contains(pit),
                    isLastMove: game.lastMove == pit,
                    isValidMove: validMoves.contains(pit),
                    onTap: { onTap(pit) }
                )
                .frame(width: 44, height: 54)
            }
        }
    }
}
