import Foundation
import SwiftData

/// A finished workout. Drives history, streaks and stats. Stores enough to
/// stand alone even if the originating plan changes.
@Model
final class CompletedSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var planId: String
    var week: Int
    var sessionIndex: Int
    var durationSeconds: Int
    var runSeconds: Int
    /// Optional 1–5 "how did it feel" rating.
    var feltRating: Int?
    /// Optional manually-noted distance in meters.
    var distanceMeters: Double?

    init(id: UUID = UUID(),
         date: Date = Date(),
         planId: String,
         week: Int,
         sessionIndex: Int,
         durationSeconds: Int,
         runSeconds: Int,
         feltRating: Int? = nil,
         distanceMeters: Double? = nil) {
        self.id = id
        self.date = date
        self.planId = planId
        self.week = max(1, week)
        self.sessionIndex = max(0, sessionIndex)
        self.durationSeconds = max(0, durationSeconds)
        self.runSeconds = max(0, runSeconds)
        self.feltRating = feltRating
        self.distanceMeters = distanceMeters
    }
}
