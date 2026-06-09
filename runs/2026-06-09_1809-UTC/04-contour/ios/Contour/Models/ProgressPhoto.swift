import Foundation
import SwiftData

/// A single progress photo. The image bytes live on disk via `ImageStore`;
/// SwiftData only stores the `filename` reference — never the blob. `filename`
/// may be "" if this row was logged as a metrics-only entry, but normally set.
@Model
final class ProgressPhoto {
    var date: Date
    var poseRaw: String
    var filename: String
    var note: String
    var weightAtTime: Double?   // canonical kg, optional
    var createdAt: Date

    init(date: Date = .now,
         pose: Pose = .front,
         filename: String = "",
         note: String = "",
         weightAtTime: Double? = nil) {
        self.date = date
        self.poseRaw = pose.rawValue
        self.filename = filename
        self.note = note
        self.weightAtTime = weightAtTime
        self.createdAt = .now
    }

    var pose: Pose {
        get { Pose(rawValue: poseRaw) ?? .front }
        set { poseRaw = newValue.rawValue }
    }

    var hasImage: Bool { !filename.isEmpty }
}
