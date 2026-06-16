import Foundation
import SwiftData

@Model
final class Board {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: Int
    var symbolName: String
    var createdDate: Date
    var sortIndex: Int
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \BoardColumn.board)
    var columns: [BoardColumn]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: Int,
        symbolName: String,
        createdDate: Date = Date(),
        sortIndex: Int,
        isArchived: Bool = false,
        columns: [BoardColumn] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.createdDate = createdDate
        self.sortIndex = sortIndex
        self.isArchived = isArchived
        self.columns = columns
    }

    /// Columns ordered by sortIndex (stable for ForEach).
    var orderedColumns: [BoardColumn] {
        columns.sorted { $0.sortIndex < $1.sortIndex }
    }

    /// The "done" column is the last ordered column, if any.
    var doneColumn: BoardColumn? {
        orderedColumns.last
    }

    var allCards: [Card] {
        columns.flatMap { $0.cards }
    }
}
