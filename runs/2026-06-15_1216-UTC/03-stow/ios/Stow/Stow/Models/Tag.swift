import Foundation
import SwiftData

/// A user-defined label for grouping articles. Many-to-many with Article.
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date

    var articles: [Article]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "C86B3C",
        createdAt: Date = .now,
        articles: [Article] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.articles = articles
    }

    /// Number of non-deleted associated articles.
    var articleCount: Int { articles.count }
}

/// A curated palette for tag colors (all readable on the warm surface).
enum TagPalette {
    static let hexes: [String] = [
        "C86B3C", // rust
        "B7892E", // amber
        "4F7A4C", // sage
        "3F6E8C", // slate blue
        "8C5A86", // plum
        "A8503A", // terracotta
        "5C6B73", // stone
        "7A6A3E"  // olive
    ]

    static func color(for hex: String) -> UInt {
        UInt(hex, radix: 16) ?? 0xC86B3C
    }
}
