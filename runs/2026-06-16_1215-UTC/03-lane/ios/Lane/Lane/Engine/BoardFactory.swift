import Foundation
import SwiftData

/// Builds boards/columns from templates. WIP limits are only applied when `isPro`.
enum BoardFactory {

    static func makeBoard(
        name: String,
        colorHex: Int,
        symbolName: String,
        template: BoardTemplate,
        sortIndex: Int,
        isPro: Bool,
        context: ModelContext
    ) -> Board {
        let board = Board(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            symbolName: symbolName,
            sortIndex: sortIndex
        )
        context.insert(board)

        for (i, spec) in template.columns.enumerated() {
            let colorHex = Palette.columnColors[safe: i] ?? Palette.columnColors.first ?? 0x8E97A6
            let column = BoardColumn(
                name: spec.name,
                sortIndex: i,
                wipLimit: isPro ? spec.wip : 0,
                colorHex: colorHex,
                board: board
            )
            context.insert(column)
            board.columns.append(column)
        }
        return board
    }
}

extension Array {
    /// Bounds-checked subscript. Returns nil instead of trapping.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
