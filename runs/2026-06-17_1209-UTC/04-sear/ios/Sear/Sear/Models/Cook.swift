import Foundation
import SwiftData

/// A single cook session. Temperatures canonical in Celsius, weight in kilograms.
/// Enums are persisted as their rawValue String and exposed via computed accessors.
@Model
final class Cook {
    @Attribute(.unique) var id: UUID
    var name: String
    var proteinRaw: String
    var cut: String
    var weightKg: Double
    var methodRaw: String
    var targetInternalTempC: Double
    var ambientTempC: Double            // smoker / grill temp
    var woodType: String?
    var rubName: String?
    var statusRaw: String
    var startDate: Date?
    var restStartDate: Date?
    var finishedDate: Date?
    var resultRating: Int?              // 1...5
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TempLog.cook)
    var tempLogs: [TempLog]

    init(id: UUID = UUID(),
         name: String,
         protein: Protein,
         cut: String,
         weightKg: Double,
         method: CookMethod,
         targetInternalTempC: Double,
         ambientTempC: Double,
         woodType: String? = nil,
         rubName: String? = nil,
         status: CookStatus = .planned,
         startDate: Date? = nil,
         restStartDate: Date? = nil,
         finishedDate: Date? = nil,
         resultRating: Int? = nil,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.proteinRaw = protein.rawValue
        self.cut = cut
        self.weightKg = weightKg
        self.methodRaw = method.rawValue
        self.targetInternalTempC = targetInternalTempC
        self.ambientTempC = ambientTempC
        self.woodType = woodType
        self.rubName = rubName
        self.statusRaw = status.rawValue
        self.startDate = startDate
        self.restStartDate = restStartDate
        self.finishedDate = finishedDate
        self.resultRating = resultRating
        self.notes = notes
        self.createdAt = createdAt
        self.tempLogs = []
    }

    // MARK: Computed enum accessors

    var protein: Protein {
        get { Protein(rawValue: proteinRaw) ?? .other }
        set { proteinRaw = newValue.rawValue }
    }

    var method: CookMethod {
        get { CookMethod(rawValue: methodRaw) ?? .grill }
        set { methodRaw = newValue.rawValue }
    }

    var status: CookStatus {
        get { CookStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    // MARK: Derived helpers

    /// The most recent internal temperature reading, if any.
    var latestInternalTempC: Double? {
        tempLogs.max(by: { $0.time < $1.time })?.internalTempC
    }

    /// Temp logs sorted oldest → newest (safe copy).
    var sortedLogs: [TempLog] {
        tempLogs.sorted { $0.time < $1.time }
    }

    var clampedRating: Int? {
        guard let r = resultRating else { return nil }
        return min(max(r, 1), 5)
    }
}
