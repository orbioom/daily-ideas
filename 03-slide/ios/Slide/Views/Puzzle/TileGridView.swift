import SwiftUI

struct TileGridView: View {
    @Binding var puzzle: SlidePuzzle
    let theme: SlideArtTheme
    @Binding var isSolved: Bool
    let reduceMotion: Bool
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        GeometryReader { geo in
            let size = puzzle.size
            let cellSize = min(geo.size.width, geo.size.height) / CGFloat(size) - 4
            let actualReduceMotion = reduceMotion || accessibilityReduceMotion
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 4), count: size),
                spacing: 4
            ) {
                ForEach(0..<(size * size), id: \.self) { index in
                    let tile = puzzle.tiles[index]
                    if tile == 0 {
                        // Blank space
                        Rectangle()
                            .fill(SlideTheme.background)
                            .frame(width: cellSize, height: cellSize)
                            .accessibilityLabel("Empty space")
                    } else {
                        TileView(tile: tile, total: size * size - 1, size: cellSize, theme: theme)
                            .onTapGesture { slideTile(at: index) }
                            .accessibilityLabel("Tile \(tile)")
                            .accessibilityAddTraits(.isButton)
                            .animation(
                                actualReduceMotion
                                    ? .none
                                    : .spring(response: 0.18, dampingFraction: 0.8),
                                value: puzzle.tiles[index]
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func slideTile(at index: Int) {
        let moved = puzzle.slide(at: index)
        if moved {
            if puzzle.isSolved { isSolved = true }
        }
    }
}
