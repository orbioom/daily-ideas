import Foundation
import SwiftData

@Model
final class RehearsalSession {
    var date: Date
    /// Seconds actually spent scrolling (pauses excluded).
    var duration: TimeInterval
    /// Words covered by the scroll position reached.
    var wordsRead: Int
    var completed: Bool
    var script: Script?

    init(date: Date = .now, duration: TimeInterval, wordsRead: Int, completed: Bool, script: Script?) {
        self.date = date
        self.duration = duration
        self.wordsRead = wordsRead
        self.completed = completed
        self.script = script
    }

    /// Effective reading pace for the session, words per minute.
    var wordsPerMinute: Int {
        guard duration > 0 else { return 0 }
        return Int((Double(wordsRead) / duration * 60).rounded())
    }
}
