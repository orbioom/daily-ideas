import Foundation
import SwiftData

/// A single book in the reader's library. Since there are no cover images, each
/// book gets a deterministic `spineColorHex` derived from its title so shelves
/// stay visually distinct and stable across launches.
@Model
final class Book {
    var title: String
    var author: String
    var totalPages: Int
    var currentPage: Int
    var genreRaw: String
    var statusRaw: String
    var rating: Int            // 0…5
    var formatRaw: String
    var spineColorHex: String
    var startedAt: Date?
    var finishedAt: Date?
    var notes: String
    var addedAt: Date

    /// Sessions are owned by the book and removed with it.
    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book) var sessions: [ReadingSession]
    /// Many-to-many with custom mood / genre tags. The inverse is declared on
    /// `BookTag.books` only (SwiftData requires the inverse on a single side).
    @Relationship var tags: [BookTag]

    init(title: String,
         author: String,
         totalPages: Int,
         currentPage: Int = 0,
         genre: BookGenre = .fiction,
         status: ReadingStatus = .wantToRead,
         rating: Int = 0,
         format: BookFormat = .paper,
         startedAt: Date? = nil,
         finishedAt: Date? = nil,
         notes: String = "",
         addedAt: Date = .now,
         tags: [BookTag] = []) {
        self.title = title
        self.author = author
        self.totalPages = max(1, totalPages)
        self.currentPage = max(0, min(currentPage, max(1, totalPages)))
        self.genreRaw = genre.rawValue
        self.statusRaw = status.rawValue
        self.rating = min(max(rating, 0), 5)
        self.formatRaw = format.rawValue
        self.spineColorHex = Book.spineColor(for: title)
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.notes = notes
        self.addedAt = addedAt
        self.sessions = []
        self.tags = tags
    }

    // MARK: - Enum accessors

    var genre: BookGenre {
        get { BookGenre(rawValue: genreRaw) ?? .other }
        set { genreRaw = newValue.rawValue }
    }

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    var format: BookFormat {
        get { BookFormat(rawValue: formatRaw) ?? .paper }
        set { formatRaw = newValue.rawValue }
    }

    // MARK: - Derived

    /// Reading progress 0…1, clamped and guarded against zero-page books.
    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return min(max(Double(currentPage) / Double(totalPages), 0), 1)
    }

    /// Pages remaining to reach the end.
    var pagesRemaining: Int { max(0, totalPages - currentPage) }

    /// Whole days from start to finish for a finished book, if both dates exist.
    var daysToFinish: Int? {
        guard let startedAt, let finishedAt, finishedAt >= startedAt else { return nil }
        let cal = Calendar.current
        let from = cal.startOfDay(for: startedAt)
        let to = cal.startOfDay(for: finishedAt)
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    /// A SwiftUI Color for the spine, parsed from the stored hex.
    var spineColor: UInt32 {
        UInt32(spineColorHex, radix: 16) ?? 0xA66A3E
    }

    // MARK: - Deterministic spine color

    /// Generates a stable, pleasant spine hex from the title text. Same title
    /// always yields the same color, with no randomness or persistence cost.
    static func spineColor(for title: String) -> String {
        var hash: UInt64 = 1469598103934665603
        for byte in title.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        // Pick a hue from the hash, keep saturation/brightness in a calm range
        // so spines read as muted book cloth rather than neon.
        let hue = Double(hash % 360) / 360.0
        let sat = 0.42 + Double((hash >> 8) % 18) / 100.0   // 0.42…0.59
        let bri = 0.52 + Double((hash >> 16) % 16) / 100.0  // 0.52…0.67
        let (r, g, b) = Book.hsbToRGB(h: hue, s: sat, v: bri)
        let value = (UInt32(r * 255) << 16) | (UInt32(g * 255) << 8) | UInt32(b * 255)
        return String(format: "%06X", value)
    }

    private static func hsbToRGB(h: Double, s: Double, v: Double) -> (Double, Double, Double) {
        if s <= 0 { return (v, v, v) }
        let hh = (h.truncatingRemainder(dividingBy: 1.0)) * 6.0
        let i = Int(hh)
        let f = hh - Double(i)
        let p = v * (1 - s)
        let q = v * (1 - s * f)
        let t = v * (1 - s * (1 - f))
        switch i % 6 {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }
}
