import Foundation
import SwiftData

/// A record of a completed (or abandoned) training session.
@Model
final class SessionLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var programName: String
    var completedReps: Int
    var totalReps: Int
    var durationSeconds: Int
    var finished: Bool

    init(id: UUID = UUID(),
         date: Date,
         programName: String,
         completedReps: Int,
         totalReps: Int,
         durationSeconds: Int,
         finished: Bool) {
        self.id = id
        self.date = date
        self.programName = programName
        self.completedReps = max(0, completedReps)
        self.totalReps = max(0, totalReps)
        self.durationSeconds = max(0, durationSeconds)
        self.finished = finished
    }
}

extension SessionLog {
    var durationMinutes: Double {
        Double(durationSeconds) / 60.0
    }
}
