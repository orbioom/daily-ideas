import Foundation
import SwiftData

/// A single logged watch (a "diary" entry) belonging to a Title. Cascade child of Title.
@Model
final class DiaryEntry {
    @Attribute(.unique) var id: UUID
    var watchedDate: Date
    /// 0...5 in half-star steps.
    var rating: Double
    var review: String
    var isRewatch: Bool
    var title: Title?

    init(watchedDate: Date = .now,
         rating: Double = 0,
         review: String = "",
         isRewatch: Bool = false) {
        self.id = UUID()
        self.watchedDate = watchedDate
        self.rating = min(max(rating, 0), 5)
        self.review = review
        self.isRewatch = isRewatch
    }
}
