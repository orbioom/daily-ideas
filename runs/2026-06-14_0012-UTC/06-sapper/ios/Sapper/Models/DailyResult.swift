import Foundation
import SwiftData

/// One day's daily-challenge outcome, keyed by "yyyy-MM-dd" so the calendar/streak
/// view can look results up by date.
@Model
final class DailyResult {
    var dateKey: String
    var won: Bool
    var durationSec: Double

    init(dateKey: String, won: Bool, durationSec: Double) {
        self.dateKey = dateKey
        self.won = won
        self.durationSec = durationSec
    }
}
