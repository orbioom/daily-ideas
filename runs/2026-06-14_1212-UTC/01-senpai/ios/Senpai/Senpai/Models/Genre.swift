import Foundation
import SwiftData

/// A genre tag, many-to-many with Title.
@Model
final class Genre {
    @Attribute(.unique) var name: String

    @Relationship(inverse: \Title.genres)
    var titles: [Title] = []

    init(name: String) {
        self.name = name
    }
}

extension Genre {
    /// The standard seed set of genres.
    static let standardNames: [String] = [
        "Action", "Adventure", "Comedy", "Drama", "Fantasy", "Sci-Fi",
        "Slice of Life", "Romance", "Horror", "Thriller", "Mystery", "Sports",
        "Isekai", "Mecha", "Shounen", "Shoujo", "Seinen", "Psychological",
        "Supernatural", "Music"
    ]

    /// Find an existing genre by name (case-insensitive) or create and insert one.
    static func findOrCreate(_ name: String, in context: ModelContext) -> Genre {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<Genre>()
        if let all = try? context.fetch(descriptor),
           let match = all.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match
        }
        let genre = Genre(name: trimmed)
        context.insert(genre)
        return genre
    }
}
