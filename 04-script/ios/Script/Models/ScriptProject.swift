import Foundation
import SwiftData

@Model
final class ScriptProject {
    var id: UUID
    var title: String
    var author: String
    var genre: String
    var logline: String
    var draftNumber: String
    var createdAt: Date
    var updatedAt: Date
    var content: String
    var isFavorite: Bool
    var colorTag: String
    var storyNotes: String

    init(
        title: String = "Untitled Script",
        author: String = "",
        genre: String = "Drama",
        logline: String = "",
        draftNumber: String = "First Draft"
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.genre = genre
        self.logline = logline
        self.draftNumber = draftNumber
        self.createdAt = .now
        self.updatedAt = .now
        self.content = ""
        self.isFavorite = false
        self.colorTag = "#F4A261"
        self.storyNotes = ""
    }
}
