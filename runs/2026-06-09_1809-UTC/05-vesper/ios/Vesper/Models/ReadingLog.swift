import Foundation
import SwiftData

/// A record that the user read a devotion on a given day, with an optional
/// reflection note. Drives the reading streak and per-devotion history.
@Model
final class ReadingLog {
    var date: Date
    var devotionID: Int
    var note: String

    init(date: Date = .now, devotionID: Int, note: String = "") {
        self.date = date
        self.devotionID = devotionID
        self.note = note
    }
}
