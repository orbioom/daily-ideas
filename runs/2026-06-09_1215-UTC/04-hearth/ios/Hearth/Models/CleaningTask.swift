import Foundation
import SwiftData

/// A recurring cleaning chore that belongs to a `Room`. Tracks how often it
/// should be done and when it was last completed. `roomName` is snapshotted so
/// completion logs remain meaningful even if the room is renamed or deleted.
@Model
final class CleaningTask {
    var name: String
    var frequencyDays: Int      // clamped 1…365
    var lastDone: Date?         // nil = never done
    var estMinutes: Int         // clamped 0…600
    var isActive: Bool
    var sortIndex: Int
    var createdAt: Date
    var roomName: String        // snapshot of the owning room's name

    var room: Room?

    init(name: String,
         frequencyDays: Int,
         lastDone: Date? = nil,
         estMinutes: Int = 10,
         isActive: Bool = true,
         sortIndex: Int = 0,
         roomName: String = "") {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.frequencyDays = min(max(frequencyDays, 1), 365)
        self.lastDone = lastDone
        self.estMinutes = min(max(estMinutes, 0), 600)
        self.isActive = isActive
        self.sortIndex = sortIndex
        self.createdAt = .now
        self.roomName = roomName
    }

    /// Safe setter that re-applies clamping for edits from the UI.
    func update(name: String, frequencyDays: Int, estMinutes: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { self.name = trimmed }
        self.frequencyDays = min(max(frequencyDays, 1), 365)
        self.estMinutes = min(max(estMinutes, 0), 600)
    }
}
