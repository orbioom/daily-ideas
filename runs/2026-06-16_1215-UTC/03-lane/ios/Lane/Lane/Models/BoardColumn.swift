import Foundation
import SwiftData

/// A column ("lane") on a board. Named `BoardColumn` to avoid clashing with
/// SwiftUI's layout `Column` / `GridRow` family.
@Model
final class BoardColumn {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortIndex: Int
    /// 0 = no WIP limit.
    var wipLimit: Int
    var colorHex: Int

    var board: Board?

    @Relationship(deleteRule: .cascade, inverse: \Card.column)
    var cards: [Card]

    init(
        id: UUID = UUID(),
        name: String,
        sortIndex: Int,
        wipLimit: Int = 0,
        colorHex: Int,
        board: Board? = nil,
        cards: [Card] = []
    ) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.wipLimit = wipLimit
        self.colorHex = colorHex
        self.board = board
        self.cards = cards
    }

    /// Cards ordered by sortIndex (stable for ForEach).
    var orderedCards: [Card] {
        cards.sorted { $0.sortIndex < $1.sortIndex }
    }

    var hasWipLimit: Bool { wipLimit > 0 }

    var isOverWipLimit: Bool {
        hasWipLimit && cards.count > wipLimit
    }
}
