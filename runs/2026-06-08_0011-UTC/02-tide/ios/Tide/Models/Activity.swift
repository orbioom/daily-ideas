import Foundation
import SwiftData

/// A taggable activity ("Exercise", "Work", "Friends") that can be attached to
/// mood entries and later correlated against how you felt.
@Model
final class Activity {
    var id: UUID
    var name: String
    var symbol: String
    var category: String
    var order: Int
    var isArchived: Bool
    @Relationship(inverse: \MoodEntry.activities) var entries: [MoodEntry]

    init(id: UUID = UUID(),
         name: String,
         symbol: String,
         category: String,
         order: Int = 0,
         isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.category = category
        self.order = order
        self.isArchived = isArchived
        self.entries = []
    }

    static func ensureDefaults(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Activity>())) ?? 0
        guard existing == 0 else { return }
        let seeds: [(String, String, String)] = [
            ("Exercise", "figure.run", "Body"),
            ("Good sleep", "bed.double.fill", "Body"),
            ("Healthy food", "carrot.fill", "Body"),
            ("Work", "laptopcomputer", "Day"),
            ("Study", "book.fill", "Day"),
            ("Chores", "house.fill", "Day"),
            ("Friends", "person.2.fill", "Social"),
            ("Family", "heart.fill", "Social"),
            ("Alone time", "moon.fill", "Social"),
            ("Outdoors", "leaf.fill", "Joy"),
            ("Reading", "books.vertical.fill", "Joy"),
            ("Screen time", "iphone", "Joy"),
        ]
        for (i, s) in seeds.enumerated() {
            context.insert(Activity(name: s.0, symbol: s.1, category: s.2, order: i))
        }
        try? context.save()
    }
}
