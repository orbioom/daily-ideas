import Foundation
import SwiftData

@Model
final class RunLog {
    var id: UUID
    var date: Date
    var distanceKm: Double
    var durationSeconds: Int
    var perceivedEffort: Int     // 1-5 (RPE)
    var runType: String
    var notes: String
    var linkedPlanRunId: UUID?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        distanceKm: Double = 0,
        durationSeconds: Int = 0,
        perceivedEffort: Int = 3,
        runType: String = RunType.easy.rawValue,
        notes: String = "",
        linkedPlanRunId: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.distanceKm = distanceKm
        self.durationSeconds = durationSeconds
        self.perceivedEffort = perceivedEffort
        self.runType = runType
        self.notes = notes
        self.linkedPlanRunId = linkedPlanRunId
    }

    var paceSecondsPerKm: Double {
        guard distanceKm > 0, durationSeconds > 0 else { return 0 }
        return Double(durationSeconds) / distanceKm
    }

    var type: RunType {
        RunType(rawValue: runType) ?? .easy
    }

    var effortLabel: String {
        switch perceivedEffort {
        case 1: return "Very Easy"
        case 2: return "Easy"
        case 3: return "Moderate"
        case 4: return "Hard"
        case 5: return "Max Effort"
        default: return "Moderate"
        }
    }
}
