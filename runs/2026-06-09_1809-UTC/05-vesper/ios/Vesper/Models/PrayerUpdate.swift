import Foundation
import SwiftData

/// A single dated reflection on a prayer — a note about how things are unfolding,
/// a renewed request, or a small answered moment along the way.
@Model
final class PrayerUpdate {
    var date: Date
    var text: String

    /// Inverse of `Prayer.updates`. Nullified automatically if the parent is gone.
    var prayer: Prayer?

    init(date: Date = .now, text: String, prayer: Prayer? = nil) {
        self.date = date
        self.text = text
        self.prayer = prayer
    }
}
