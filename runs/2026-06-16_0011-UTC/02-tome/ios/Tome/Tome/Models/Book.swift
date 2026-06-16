import SwiftUI
import SwiftData

/// A book in the reader's library, with progress, rating, sessions, and tags.
@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var pageCount: Int
    var currentPage: Int
    /// Stored as raw string; access via `shelf`.
    var shelfRaw: String
    /// Stored as raw string; access via `format`.
    var formatRaw: String
    var rating: Double?          // 0...5, half steps
    var startedDate: Date?
    var finishedDate: Date?
    var colorSeed: Int           // drives the generated gradient cover
    var review: String
    var seriesName: String
    var seriesNumber: Int
    var dateAdded: Date
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var sessions: [ReadingSession] = []

    /// Many-to-many moods/genres. Inverse declared on `Tag`.
    var tags: [Tag] = []

    init(title: String,
         author: String,
         pageCount: Int,
         currentPage: Int = 0,
         shelf: Shelf = .wantToRead,
         format: BookFormat = .paperback,
         rating: Double? = nil,
         startedDate: Date? = nil,
         finishedDate: Date? = nil,
         colorSeed: Int = 0,
         review: String = "",
         seriesName: String = "",
         seriesNumber: Int = 0,
         dateAdded: Date = .now,
         isFavorite: Bool = false) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.pageCount = max(0, pageCount)
        self.currentPage = max(0, currentPage)
        self.shelfRaw = shelf.rawValue
        self.formatRaw = format.rawValue
        self.rating = rating
        self.startedDate = startedDate
        self.finishedDate = finishedDate
        self.colorSeed = colorSeed
        self.review = review
        self.seriesName = seriesName
        self.seriesNumber = seriesNumber
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
    }

    var shelf: Shelf {
        get { Shelf(rawValue: shelfRaw) ?? .wantToRead }
        set { shelfRaw = newValue.rawValue }
    }

    var format: BookFormat {
        get { BookFormat(rawValue: formatRaw) ?? .paperback }
        set { formatRaw = newValue.rawValue }
    }

    /// Fractional reading progress 0...1. Guards a zero page count.
    var progress: Double {
        guard pageCount > 0 else { return shelf == .finished ? 1 : 0 }
        if shelf == .finished { return 1 }
        return min(1, max(0, Double(currentPage) / Double(pageCount)))
    }

    /// Pages remaining to the end. Never negative.
    var pagesRemaining: Int {
        max(0, pageCount - currentPage)
    }

    /// First initial of title and author, for the generated cover.
    var coverInitials: String {
        let t = title.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?"
        let a = author.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? ""
        return (t + a).uppercased()
    }

    /// Display label like "Dune #1" when part of a series.
    var seriesLabel: String? {
        let name = seriesName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        return seriesNumber > 0 ? "\(name) #\(seriesNumber)" : name
    }

    /// Primary genre tag name (first tag), if any — used for stats grouping.
    var primaryGenre: String {
        tags.first?.name ?? "Untagged"
    }
}
