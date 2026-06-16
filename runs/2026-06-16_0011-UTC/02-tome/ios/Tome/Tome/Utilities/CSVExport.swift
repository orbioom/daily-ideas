import Foundation

/// Builds a CSV export of the library. Pure & guarded — no force-unwraps.
enum CSVExport {

    /// CSV-escapes a single field (quotes, commas, newlines).
    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let doubled = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return value
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoFormatter.string(from: date)
    }

    /// Produces the full CSV text for the given books.
    static func build(books: [Book]) -> String {
        let header = ["Title", "Author", "Series", "Series #", "Pages", "Current Page",
                      "Shelf", "Format", "Rating", "Started", "Finished",
                      "Sessions", "Pages Logged", "Genres/Tags", "Favorite", "Review"]

        var rows: [String] = [header.map(escape).joined(separator: ",")]

        let ordered = books.sorted { $0.dateAdded > $1.dateAdded }
        for book in ordered {
            let pagesLogged = book.sessions.reduce(0) { $0 + max(0, $1.pagesRead) }
            let tags = book.tags.map { $0.name }.joined(separator: "; ")
            let rating = book.rating.map { String(format: "%.1f", $0) } ?? ""
            let fields: [String] = [
                book.title,
                book.author,
                book.seriesName,
                book.seriesNumber > 0 ? String(book.seriesNumber) : "",
                String(book.pageCount),
                String(book.currentPage),
                book.shelf.displayName,
                book.format.displayName,
                rating,
                dateString(book.startedDate),
                dateString(book.finishedDate),
                String(book.sessions.count),
                String(pagesLogged),
                tags,
                book.isFavorite ? "Yes" : "No",
                book.review
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }
}
