import Foundation
import SwiftData

@Model
final class Folder {
    var name: String
    var symbol: String          // SF Symbol name
    var colorIndex: Int
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Note.folder)
    var notes: [Note] = []

    init(name: String, symbol: String = "folder", colorIndex: Int = 0, sortOrder: Int = 0) {
        self.name = name
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}

@Model
final class Tag {
    @Attribute(.unique) var name: String
    var createdAt: Date

    @Relationship(inverse: \Note.tags)
    var notes: [Note] = []

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }
}

@Model
final class Note {
    var title: String
    var body: String            // markdown source
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isArchived: Bool
    var colorIndex: Int

    var folder: Folder?
    var tags: [Tag] = []

    init(title: String = "", body: String = "", folder: Folder? = nil) {
        self.title = title
        self.body = body
        self.createdAt = .now
        self.updatedAt = .now
        self.isPinned = false
        self.isArchived = false
        self.colorIndex = 0
        self.folder = folder
    }

    /// First non-empty line of the body, for list previews.
    var snippet: String {
        let lines = body.split(separator: "\n", omittingEmptySubsequences: true)
        for line in lines {
            let cleaned = MarkdownTools.stripInline(String(line))
                .trimmingCharacters(in: .whitespaces)
            if !cleaned.isEmpty { return cleaned }
        }
        return ""
    }

    var displayTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        let s = snippet
        return s.isEmpty ? "Untitled" : String(s.prefix(60))
    }

    var wordCount: Int {
        body.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }
}
