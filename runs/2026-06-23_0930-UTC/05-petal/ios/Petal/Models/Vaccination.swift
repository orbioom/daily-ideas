import Foundation
import SwiftData

/// A vaccination record with the date administered and the next-due (booster) date.
@Model
final class Vaccination {
    var id: UUID
    var name: String
    var dateAdministered: Date
    var nextDue: Date?
    var clinic: String
    var lotNumber: String
    var notes: String
    var createdAt: Date

    var pet: Pet?

    init(
        id: UUID = UUID(),
        name: String,
        dateAdministered: Date,
        nextDue: Date? = nil,
        clinic: String = "",
        lotNumber: String = "",
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.dateAdministered = dateAdministered
        self.nextDue = nextDue
        self.clinic = clinic
        self.lotNumber = lotNumber
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Records a booster: pushes the administered date to now and clears/sets next due.
    func renew(on date: Date, nextDue: Date?) {
        self.dateAdministered = date
        self.nextDue = nextDue
    }
}

/// Common core vaccinations offered as quick-pick suggestions.
enum CommonVaccine: String, CaseIterable, Identifiable {
    case rabies = "Rabies"
    case dhpp = "DHPP"
    case bordetella = "Bordetella"
    case leptospirosis = "Leptospirosis"
    case fvrcp = "FVRCP"
    case felv = "FeLV"
    case lyme = "Lyme"
    case caliciNumber = "Calicivirus"
    var id: String { rawValue }
    var label: String { rawValue }
}
