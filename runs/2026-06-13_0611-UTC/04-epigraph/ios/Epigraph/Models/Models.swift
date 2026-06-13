import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var category: String
    var spineColor: Int
    var createdAt: Date
    var isFinished: Bool

    @Relationship(deleteRule: .cascade, inverse: \Highlight.book)
    var highlights: [Highlight] = []

    init(title: String, author: String = "", category: String = "Nonfiction",
         spineColor: Int = 0, isFinished: Bool = false) {
        self.title = title
        self.author = author
        self.category = category
        self.spineColor = spineColor
        self.createdAt = .now
        self.isFinished = isFinished
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : title
    }
    var highlightCount: Int { highlights.count }
}

@Model
final class Tag {
    @Attribute(.unique) var name: String
    var createdAt: Date
    @Relationship(inverse: \Highlight.tags)
    var highlights: [Highlight] = []
    init(name: String) { self.name = name; self.createdAt = .now }
}

@Model
final class Highlight {
    var text: String
    var note: String            // your annotation
    var location: String        // page / chapter / location
    var createdAt: Date
    var isFavorite: Bool
    var lastSurfaced: Date      // for resurfacing rotation
    var surfaceCount: Int

    var book: Book?
    var tags: [Tag] = []

    init(text: String, note: String = "", location: String = "", book: Book? = nil) {
        self.text = text
        self.note = note
        self.location = location
        self.createdAt = .now
        self.isFavorite = false
        self.lastSurfaced = .distantPast
        self.surfaceCount = 0
        self.book = book
    }

    var wordCount: Int { text.split { $0 == " " || $0 == "\n" }.count }
}

enum BookCatalog {
    static let categories = ["Nonfiction", "Fiction", "Philosophy", "Poetry", "Science",
                             "Business", "Self-help", "History", "Biography", "Essays"]
    static func icon(for category: String) -> String {
        switch category {
        case "Fiction": return "books.vertical"
        case "Philosophy": return "brain.head.profile"
        case "Poetry": return "quote.opening"
        case "Science": return "atom"
        case "Business": return "chart.line.uptrend.xyaxis"
        case "Self-help": return "figure.mind.and.body"
        case "History": return "scroll"
        case "Biography": return "person.crop.rectangle"
        case "Essays": return "doc.text"
        default: return "book.closed"
        }
    }
}
