import SwiftUI

struct BoardView: View {
    let vm: GameViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cellSize: CGFloat = 42

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        CellView(
                            piece: vm.board[row,col],
                            isHint: vm.showHints && vm.isPlayerTurn && vm.validMoves.contains(where: { $0 == (row,col) }),
                            isLastPlaced: vm.lastPlaced.map { $0 == (row,col) } ?? false,
                            isAnimating: vm.animatingFlips.contains(where: { $0 == (row,col) }),
                            reduceMotion: reduceMotion
                        ) {
                            if vm.isPlayerTurn { vm.playerMove(row: row, col: col) }
                        }
                        .frame(width: cellSize, height: cellSize)
                        .accessibilityLabel(cellLabel(row: row, col: col))
                        .accessibilityAddTraits(
                            vm.showHints && vm.isPlayerTurn && vm.validMoves.contains(where: { $0 == (row,col) }) ? .isButton : []
                        )
                    }
                }
            }
        }
        .background(Color(red: 0.15, green: 0.50, blue: 0.30))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.10, green: 0.35, blue: 0.20), lineWidth: 2))
    }

    private func cellLabel(row: Int, col: Int) -> String {
        let files = ["a","b","c","d","e","f","g","h"]
        let piece = vm.board[row,col]
        let name = piece == .black ? "Black disc" : piece == .white ? "White disc" : "Empty"
        let hint = vm.showHints && vm.isPlayerTurn && vm.validMoves.contains(where: { $0 == (row,col) }) ? ", valid move" : ""
        return "\(files[col])\(8-row): \(name)\(hint)"
    }
}

struct CellView: View {
    let piece: Piece?
    let isHint: Bool
    let isLastPlaced: Bool
    let isAnimating: Bool
    let reduceMotion: Bool
    let onTap: () -> Void
    @State private var flipAngle: Double = 0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.15, green: 0.50, blue: 0.30))
            Rectangle()
                .stroke(Color(red: 0.10, green: 0.35, blue: 0.20).opacity(0.6), lineWidth: 0.5)
            if isHint && piece == nil {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .padding(12)
            }
            if let p = piece {
                DiscView(piece: p, highlighted: isLastPlaced)
                    .padding(4)
                    .rotation3DEffect(.degrees(flipAngle), axis: (1, 0, 0))
                    .onChange(of: p) { _, _ in
                        guard !reduceMotion && isAnimating else { return }
                        withAnimation(.linear(duration: 0.15)) { flipAngle = 90 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.linear(duration: 0.15)) { flipAngle = 0 }
                        }
                    }
            }
        }
        .onTapGesture(perform: onTap)
    }
}
