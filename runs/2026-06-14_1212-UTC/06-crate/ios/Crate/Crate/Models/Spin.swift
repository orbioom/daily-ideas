import Foundation
import SwiftData

/// A logged listening session ("spin"). Cascade child of `Record`.
@Model
final class Spin {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Optional 0–5 play rating (0 = not rated).
    var rating: Int
    var note: String
    var record: Record?

    init(date: Date = .now, rating: Int = 0, note: String = "") {
        self.id = UUID()
        self.date = date
        self.rating = min(max(rating, 0), 5)
        self.note = note
    }

    var dateLabel: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
