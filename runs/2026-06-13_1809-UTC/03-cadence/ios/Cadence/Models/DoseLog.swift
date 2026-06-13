import Foundation
import SwiftData

enum DoseStatus: String, Codable {
    case taken, skipped
}

@Model
final class DoseLog {
    var id: UUID
    var medID: UUID
    var medName: String
    var statusRaw: String
    var scheduledAt: Date        // the planned slot (date + time); for PRN, == takenAt
    var takenAt: Date
    var unitCount: Double
    var wasAsNeeded: Bool

    init(medID: UUID, medName: String, status: DoseStatus,
         scheduledAt: Date, takenAt: Date = Date(), unitCount: Double, wasAsNeeded: Bool = false) {
        self.id = UUID()
        self.medID = medID
        self.medName = medName
        self.statusRaw = status.rawValue
        self.scheduledAt = scheduledAt
        self.takenAt = takenAt
        self.unitCount = unitCount
        self.wasAsNeeded = wasAsNeeded
    }

    var status: DoseStatus {
        get { DoseStatus(rawValue: statusRaw) ?? .taken }
        set { statusRaw = newValue.rawValue }
    }
}
