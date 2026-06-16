import Foundation
import SwiftData

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isDone: Bool
    var sortIndex: Int

    var card: Card?

    init(
        id: UUID = UUID(),
        text: String,
        isDone: Bool = false,
        sortIndex: Int,
        card: Card? = nil
    ) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.sortIndex = sortIndex
        self.card = card
    }
}
