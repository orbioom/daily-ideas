import Foundation
import SwiftData

/// A logged veterinary visit.
@Model
final class VetVisit {
    var id: UUID
    var date: Date
    var reasonRaw: String
    var clinic: String
    var vetName: String
    var diagnosis: String
    var notes: String
    /// Cost in the user's currency. Informational only — Petal is not a finance app.
    var cost: Double
    var followUpDate: Date?
    var createdAt: Date

    var pet: Pet?

    init(
        id: UUID = UUID(),
        date: Date,
        reason: VisitReason = .checkup,
        clinic: String = "",
        vetName: String = "",
        diagnosis: String = "",
        notes: String = "",
        cost: Double = 0,
        followUpDate: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.reasonRaw = reason.rawValue
        self.clinic = clinic
        self.vetName = vetName
        self.diagnosis = diagnosis
        self.notes = notes
        self.cost = cost
        self.followUpDate = followUpDate
        self.createdAt = createdAt
    }

    var reason: VisitReason {
        get { VisitReason(rawValue: reasonRaw) ?? .checkup }
        set { reasonRaw = newValue.rawValue }
    }
}

enum VisitReason: String, CaseIterable, Identifiable, Codable {
    case checkup, vaccination, illness, injury, dental, surgery, grooming, emergency
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .checkup: return "stethoscope"
        case .vaccination: return "syringe.fill"
        case .illness: return "thermometer.medium"
        case .injury: return "bandage.fill"
        case .dental: return "mouth.fill"
        case .surgery: return "cross.case.fill"
        case .grooming: return "comb.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        }
    }
}
