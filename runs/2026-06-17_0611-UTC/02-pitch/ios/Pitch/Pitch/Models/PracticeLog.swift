import Foundation
import SwiftData

/// A logged metronome practice session — minutes spent at a given tempo on a day.
/// Powers the Charts summary on the Metronome screen.
@Model
final class PracticeLog {
    var uuid: String
    var date: Date
    var minutes: Double
    var bpm: Int

    init(date: Date, minutes: Double, bpm: Int) {
        self.uuid = UUID().uuidString
        self.date = date
        self.minutes = max(0, minutes)
        self.bpm = bpm
    }
}
