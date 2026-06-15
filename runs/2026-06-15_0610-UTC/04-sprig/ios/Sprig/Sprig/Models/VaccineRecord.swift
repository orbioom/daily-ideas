import Foundation
import SwiftData

/// A child's status for one dose from the curated immunization schedule, keyed by `vaccineKey`.
/// `givenDate` nil means not yet given (due/overdue computed from child age vs schedule).
@Model
final class VaccineRecord {
    @Attribute(.unique) var id: UUID
    var vaccineKey: String
    var givenDate: Date?
    var child: Child?

    init(id: UUID = UUID(),
         vaccineKey: String,
         givenDate: Date? = nil,
         child: Child? = nil) {
        self.id = id
        self.vaccineKey = vaccineKey
        self.givenDate = givenDate
        self.child = child
    }

    var isGiven: Bool { givenDate != nil }

    /// The catalog definition this record points to, if it still exists.
    var dose: VaccineDose? { VaccineCatalog.byKey[vaccineKey] }
}
