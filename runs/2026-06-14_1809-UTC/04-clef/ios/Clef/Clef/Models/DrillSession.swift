import Foundation
import SwiftData

/// The mode a drill was run in.
enum DrillMode: String, CaseIterable, Identifiable, Codable {
    case fixedCount
    case timed
    var id: String { rawValue }

    var label: String {
        switch self {
        case .fixedCount: return "Fixed count"
        case .timed: return "Timed 60s"
        }
    }
}

/// One completed practice session, persisted for the Progress screen.
@Model
final class DrillSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var clefRaw: String
    var modeRaw: String
    var total: Int
    var correct: Int
    var durationSec: Int
    var avgMs: Double
    var bestStreak: Int

    init(id: UUID = UUID(),
         date: Date = Date(),
         clef: Clef,
         mode: DrillMode,
         total: Int,
         correct: Int,
         durationSec: Int,
         avgMs: Double,
         bestStreak: Int) {
        self.id = id
        self.date = date
        self.clefRaw = clef.rawValue
        self.modeRaw = mode.rawValue
        self.total = max(0, total)
        self.correct = max(0, correct)
        self.durationSec = max(0, durationSec)
        self.avgMs = max(0, avgMs)
        self.bestStreak = max(0, bestStreak)
    }

    var clef: Clef { Clef(rawValue: clefRaw) ?? .treble }
    var mode: DrillMode { DrillMode(rawValue: modeRaw) ?? .fixedCount }

    /// Accuracy 0...1, guarded against divide-by-zero.
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}
