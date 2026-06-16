import Foundation
import SwiftData

/// A completed practice round.
@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// An op raw value, or "mixed" for a mixed round.
    var opRaw: String
    var levelIndex: Int
    var total: Int
    var correct: Int
    var durationSec: Double
    var starsEarned: Int

    var profile: Profile?

    init(date: Date = .now,
         opRaw: String,
         levelIndex: Int,
         total: Int,
         correct: Int,
         durationSec: Double,
         starsEarned: Int) {
        self.id = UUID()
        self.date = date
        self.opRaw = opRaw
        self.levelIndex = levelIndex
        self.total = total
        self.correct = correct
        self.durationSec = durationSec
        self.starsEarned = starsEarned
    }

    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }

    var isMixed: Bool { opRaw == "mixed" }

    var op: MathOp? { isMixed ? nil : MathOp(rawValue: opRaw) }

    var modeLabel: String { isMixed ? "Mixed" : (op?.title ?? "Practice") }

    /// Average seconds per question.
    var avgSecPerQuestion: Double { total > 0 ? durationSec / Double(total) : 0 }
}
