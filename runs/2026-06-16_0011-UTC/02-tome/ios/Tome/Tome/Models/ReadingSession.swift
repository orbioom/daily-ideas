import Foundation
import SwiftData

/// A single reading session: a date, pages read, and minutes spent.
/// Owned (cascade) child of `Book`.
@Model
final class ReadingSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var pagesRead: Int
    var minutes: Int
    var book: Book?

    init(date: Date = .now, pagesRead: Int = 0, minutes: Int = 0) {
        self.id = UUID()
        self.date = date
        self.pagesRead = max(0, pagesRead)
        self.minutes = max(0, minutes)
    }
}
