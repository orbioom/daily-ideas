import Foundation
import SwiftData

/// A logged practice run: how many questions were answered, how many correct,
/// and how long it took. Drives the Progress charts and streak.
@Model
final class DrillSession {
    var date: Date
    var drillName: String
    var drillTypeRaw: String
    var total: Int
    var correct: Int
    var durationSec: Int

    init(date: Date = .now,
         drillName: String,
         drillType: DrillType,
         total: Int,
         correct: Int,
         durationSec: Int) {
        self.date = date
        self.drillName = drillName
        self.drillTypeRaw = drillType.rawValue
        self.total = max(0, total)
        self.correct = min(max(0, correct), max(0, total))
        self.durationSec = max(0, durationSec)
    }

    var drillType: DrillType { DrillType(rawValue: drillTypeRaw) ?? .interval }

    /// Fraction correct, 0…1. Guards divide-by-zero.
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}
