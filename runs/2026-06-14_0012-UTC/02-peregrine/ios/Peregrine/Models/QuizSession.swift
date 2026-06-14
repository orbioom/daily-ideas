import Foundation
import SwiftData

/// A completed quiz run, stored for the Progress screen's trend charts and
/// achievement checks. Mode and continent are kept as raw strings per the
/// SwiftData enum-storage guidance.
@Model
final class QuizSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var modeRaw: String
    var total: Int
    var correct: Int
    var durationSec: Double
    /// Raw continent value, or nil for "All continents".
    var continentRaw: String?
    /// True when this session was the deterministic daily challenge.
    var isDaily: Bool

    init(id: UUID = UUID(),
         date: Date = Date(),
         modeRaw: String,
         total: Int,
         correct: Int,
         durationSec: Double,
         continentRaw: String? = nil,
         isDaily: Bool = false) {
        self.id = id
        self.date = date
        self.modeRaw = modeRaw
        self.total = total
        self.correct = correct
        self.durationSec = durationSec
        self.continentRaw = continentRaw
        self.isDaily = isDaily
    }

    var mode: QuizMode? { QuizMode(rawValue: modeRaw) }
    var continent: Continent? {
        guard let continentRaw else { return nil }
        return Continent(rawValue: continentRaw)
    }

    /// Accuracy in 0...1, guarded against an empty run.
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}
