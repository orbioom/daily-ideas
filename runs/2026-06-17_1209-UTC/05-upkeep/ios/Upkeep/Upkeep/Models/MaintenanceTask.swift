import Foundation
import SwiftData

/// A recurring home-maintenance task. Cadence enums are stored as raw strings.
@Model
final class MaintenanceTask {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Snapshot of the owning system's name (kept in sync, also relationship below).
    var systemName: String
    /// Raw value of `CadenceType`.
    var cadenceRaw: String
    var intervalCount: Int
    /// Raw value of `Season`, when `cadenceType == .seasonal`.
    var seasonRaw: String?
    var lastDone: Date?
    var estimatedMinutes: Int
    var estimatedCost: Double?
    var priority: Int            // 1 = high, 2 = medium, 3 = low
    var isActive: Bool
    var notes: String
    var createdAt: Date

    var system: HomeSystem?

    @Relationship(deleteRule: .cascade, inverse: \CompletionLog.task)
    var logs: [CompletionLog]

    init(title: String,
         systemName: String,
         cadenceType: CadenceType,
         intervalCount: Int,
         season: Season? = nil,
         lastDone: Date? = nil,
         estimatedMinutes: Int = 15,
         estimatedCost: Double? = nil,
         priority: Int = 2,
         isActive: Bool = true,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.systemName = systemName
        self.cadenceRaw = cadenceType.rawValue
        self.intervalCount = max(1, intervalCount)
        self.seasonRaw = season?.rawValue
        self.lastDone = lastDone
        self.estimatedMinutes = max(0, estimatedMinutes)
        self.estimatedCost = estimatedCost
        self.priority = min(max(priority, 1), 3)
        self.isActive = isActive
        self.notes = notes
        self.createdAt = createdAt
        self.logs = []
    }

    // MARK: Computed accessors for stored raw enums

    var cadenceType: CadenceType {
        get { CadenceType(rawValue: cadenceRaw) ?? .everyNMonths }
        set { cadenceRaw = newValue.rawValue }
    }

    var season: Season? {
        get { seasonRaw.flatMap { Season(rawValue: $0) } }
        set { seasonRaw = newValue?.rawValue }
    }

    var priorityLabel: String {
        switch priority {
        case 1: return "High"
        case 3: return "Low"
        default: return "Medium"
        }
    }
}
