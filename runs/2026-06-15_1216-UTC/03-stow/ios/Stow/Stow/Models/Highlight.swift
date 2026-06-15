import Foundation
import SwiftData

/// A saved snippet of text the reader selected within an article.
@Model
final class Highlight {
    @Attribute(.unique) var id: UUID
    var text: String
    var note: String
    var createdAt: Date

    var article: Article?

    init(
        id: UUID = UUID(),
        text: String,
        note: String = "",
        createdAt: Date = .now,
        article: Article? = nil
    ) {
        self.id = id
        self.text = text
        self.note = note
        self.createdAt = createdAt
        self.article = article
    }
}
