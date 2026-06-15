import Foundation
import SwiftData

/// Where an article came from.
enum ArticleSource: String, Codable, CaseIterable {
    case sample
    case url
}

/// A saved, fully-extracted article available for offline reading.
@Model
final class Article {
    /// Stable identity, also used for share / dedupe.
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var byline: String
    var siteName: String
    var savedAt: Date
    var isArchived: Bool
    var isFavorite: Bool
    /// 0...1 scroll progress, persisted so the reader resumes.
    var readingProgress: Double
    var wordCount: Int
    var estMinutes: Int
    var excerpt: String
    var sourceRaw: String

    /// Ordered article blocks (headings + paragraphs) encoded to Data so SwiftData
    /// can store the structured body without a separate model table.
    var bodyData: Data

    @Relationship(deleteRule: .nullify, inverse: \Tag.articles)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade, inverse: \Highlight.article)
    var highlights: [Highlight]

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        byline: String,
        siteName: String,
        savedAt: Date = .now,
        isArchived: Bool = false,
        isFavorite: Bool = false,
        readingProgress: Double = 0,
        wordCount: Int,
        estMinutes: Int,
        excerpt: String,
        source: ArticleSource,
        blocks: [ContentBlock],
        tags: [Tag] = [],
        highlights: [Highlight] = []
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.byline = byline
        self.siteName = siteName
        self.savedAt = savedAt
        self.isArchived = isArchived
        self.isFavorite = isFavorite
        self.readingProgress = readingProgress
        self.wordCount = wordCount
        self.estMinutes = estMinutes
        self.excerpt = excerpt
        self.sourceRaw = source.rawValue
        self.bodyData = ContentBlock.encode(blocks)
        self.tags = tags
        self.highlights = highlights
    }

    // MARK: Derived

    var source: ArticleSource {
        ArticleSource(rawValue: sourceRaw) ?? .url
    }

    /// Decoded structured body. Falls back to an empty array if data is corrupt.
    var blocks: [ContentBlock] {
        ContentBlock.decode(bodyData)
    }

    /// Plain-text body (paragraphs joined) for search and share.
    var plainText: String {
        blocks.map(\.text).joined(separator: "\n\n")
    }
}

/// One renderable unit of an article body.
struct ContentBlock: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case heading
        case paragraph
    }
    var id: UUID = UUID()
    var kind: Kind
    var text: String

    static func encode(_ blocks: [ContentBlock]) -> Data {
        (try? JSONEncoder().encode(blocks)) ?? Data()
    }

    static func decode(_ data: Data) -> [ContentBlock] {
        (try? JSONDecoder().decode([ContentBlock].self, from: data)) ?? []
    }
}
