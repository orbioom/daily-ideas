import Foundation
import SwiftData

/// One record per country the user has marked. In practice there is at most one
/// VisitMark per `countryCode` (the CRUD layer upserts by code).
@Model
final class VisitMark {
    var countryCode: String
    var statusRaw: String
    var firstVisitYear: Int?
    var timesVisited: Int
    var note: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(countryCode: String,
         status: VisitStatus = .visited,
         firstVisitYear: Int? = nil,
         timesVisited: Int = 1,
         note: String = "",
         isFavorite: Bool = false) {
        self.countryCode = countryCode.uppercased()
        self.statusRaw = status.rawValue
        self.firstVisitYear = firstVisitYear
        self.timesVisited = max(0, timesVisited)
        self.note = note
        self.isFavorite = isFavorite
        self.createdAt = .now
        self.updatedAt = .now
    }

    var status: VisitStatus {
        get { VisitStatus(rawValue: statusRaw) ?? .visited }
        set { statusRaw = newValue.rawValue }
    }

    /// The static country this mark refers to, if the code is known.
    var country: Country? { CountryData.country(for: countryCode) }

    /// True when this status counts the country as one the user has set foot in
    /// (visited or lived). Transit is handled separately by the engine.
    var isGrounded: Bool { status.isGrounded }
}
