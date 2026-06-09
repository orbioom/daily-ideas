import Foundation
import SwiftData

/// A single reading session logged against a book: how many pages were read and
/// (optionally) how many minutes were spent, on a given date.
@Model
final class ReadingSession {
    var date: Date
    var pagesRead: Int
    var minutes: Int
    var note: String

    /// Inverse of `Book.sessions`; set automatically when added to a book.
    var book: Book?

    init(date: Date = .now, pagesRead: Int = 0, minutes: Int = 0, note: String = "") {
        self.date = date
        self.pagesRead = max(0, pagesRead)
        self.minutes = max(0, minutes)
        self.note = note
    }
}
