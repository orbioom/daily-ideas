import Foundation
import SwiftData

/// A record of one alarm event: when it fired, when it was finally dismissed, how many
/// snoozes it took, and which mission woke you. Drives the Stats screen. `secondsToDismiss`
/// is stored (not just computed) so historical rows survive even if the firing logic changes.
@Model
final class WakeLog {
    @Attribute(.unique) var id: UUID
    var date: Date              // the calendar day this wake belongs to (start of fired day)
    var alarmLabel: String
    var firedAt: Date
    var dismissedAt: Date
    var secondsToDismiss: Int
    var snoozeCount: Int
    var missionTypeRaw: String

    init(id: UUID = UUID(),
         alarmLabel: String = "Alarm",
         firedAt: Date = Date(),
         dismissedAt: Date = Date(),
         snoozeCount: Int = 0,
         missionType: MissionType = .math) {
        self.id = id
        self.firedAt = firedAt
        self.dismissedAt = max(dismissedAt, firedAt)
        self.date = Calendar.current.startOfDay(for: firedAt)
        self.alarmLabel = alarmLabel.isEmpty ? "Alarm" : alarmLabel
        self.secondsToDismiss = max(0, Int(self.dismissedAt.timeIntervalSince(firedAt)))
        self.snoozeCount = max(0, snoozeCount)
        self.missionTypeRaw = missionType.rawValue
    }

    var missionType: MissionType {
        MissionType(rawValue: missionTypeRaw) ?? .none
    }
}
