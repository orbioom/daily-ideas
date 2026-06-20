import SwiftUI

struct PieceTileView: View {
    let piece: PuzzlePiece
    let image: UIImage
    let cellSize: CGFloat
    let gridSize: Int
    var isSelected: Bool = false

    var body: some View {
        let total = cellSize * CGFloat(gridSize)
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: total, height: total)
            .offset(x: -CGFloat(piece.correctCol) * cellSize,
                    y: -CGFloat(piece.correctRow) * cellSize)
            .frame(width: cellSize, height: cellSize, alignment: .topLeading)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.yellow, lineWidth: 3)
                        .shadow(color: .yellow.opacity(0.6), radius: 6)
                }
            }
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .shadow(color: .black.opacity(isSelected ? 0.5 : 0.25),
                    radius: isSelected ? 8 : 3)
            .animation(.spring(duration: 0.2), value: isSelected)
            .accessibilityLabel("Puzzle piece row \(piece.correctRow + 1) column \(piece.correctCol + 1)")
    }
}

struct BoardSlotView: View {
    let row: Int
    let col: Int
    let cellSize: CGFloat
    let gridSize: Int
    let isPlaced: Bool
    let piece: PuzzlePiece?
    let image: UIImage?
    let onTap: () -> Void

    var body: some View {
        Group {
            if isPlaced, let p = piece, let img = image {
                PieceTileView(piece: p, image: img, cellSize: cellSize, gridSize: gridSize, isSelected: false)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.04)))
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture(perform: onTap)
        .accessibilityLabel("\(isPlaced ? "Filled" : "Empty") slot row \(row + 1) column \(col + 1)")
        .accessibilityAddTraits(isPlaced ? [] : .isButton)
    }
}
