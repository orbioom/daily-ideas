import Foundation
import SwiftData

/// A completed (or partial) breathing session, logged for streaks and stats.
@Model
final class BreathSession {
    var id: UUID
    var date: Date
    var patternName: String
    var plannedSeconds: Double
    var completedSeconds: Double
    var roundsCompleted: Int
    var calmBefore: Int   // 0 = not recorded, else 1...5
    var calmAfter: Int

    init(id: UUID = UUID(),
         date: Date = .now,
         patternName: String,
         plannedSeconds: Double,
         completedSeconds: Double,
         roundsCompleted: Int,
         calmBefore: Int = 0,
         calmAfter: Int = 0) {
        self.id = id
        self.date = date
        self.patternName = patternName
        self.plannedSeconds = plannedSeconds
        self.completedSeconds = completedSeconds
        self.roundsCompleted = roundsCompleted
        self.calmBefore = calmBefore
        self.calmAfter = calmAfter
    }

    var minutes: Double { completedSeconds / 60 }
    var didFinish: Bool { completedSeconds >= plannedSeconds - 0.5 }
}
