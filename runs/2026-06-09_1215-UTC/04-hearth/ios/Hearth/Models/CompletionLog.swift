import Foundation
import SwiftData

/// An immutable record that a task was completed. Independent of `CleaningTask`
/// (NOT cascade-deleted with it) so Insights and streaks survive task/room
/// deletion. Stores name snapshots for display.
@Model
final class CompletionLog {
    var date: Date
    var taskName: String
    var roomName: String
    var minutes: Int

    init(date: Date = .now,
         taskName: String,
         roomName: String,
         minutes: Int) {
        self.date = date
        self.taskName = taskName
        self.roomName = roomName
        self.minutes = max(0, minutes)
    }
}
