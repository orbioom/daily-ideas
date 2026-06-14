import Foundation
import SwiftData

/// A single progress session, created whenever the user advances a title.
/// Gives a real session history and powers the "progress over time" view.
@Model
final class WatchLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var fromUnit: Int
    var toUnit: Int
    var note: String
    var title: Title?

    init(date: Date = .now, fromUnit: Int, toUnit: Int, note: String = "") {
        self.id = UUID()
        self.date = date
        self.fromUnit = max(0, fromUnit)
        self.toUnit = max(self.fromUnit, toUnit)
        self.note = note
    }

    /// Units advanced in this session (never negative).
    var delta: Int { max(0, toUnit - fromUnit) }
}
