import Foundation
import SwiftData

/// A grouped journey referencing countries by their ISO code. Dates are
/// optional so a loosely-remembered trip can still be recorded.
@Model
final class Trip {
    var title: String
    var startDate: Date?
    var endDate: Date?
    var note: String
    /// Codable array attribute — SwiftData stores [String] transparently.
    var countryCodes: [String]
    var createdAt: Date

    init(title: String,
         startDate: Date? = nil,
         endDate: Date? = nil,
         note: String = "",
         countryCodes: [String] = []) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
        self.countryCodes = countryCodes.map { $0.uppercased() }
        self.createdAt = .now
    }

    /// Resolved countries for display, in stored order, skipping unknown codes.
    var countries: [Country] {
        countryCodes.compactMap { CountryData.country(for: $0) }
    }

    /// A friendly date-range label, or nil if no dates are set.
    var dateRangeLabel: String? {
        let fmt = Date.FormatStyle.dateTime.month(.abbreviated).year()
        switch (startDate, endDate) {
        case let (start?, end?):
            if Calendar.current.isDate(start, equalTo: end, toGranularity: .month) {
                return start.formatted(fmt)
            }
            return "\(start.formatted(fmt)) – \(end.formatted(fmt))"
        case let (start?, nil):
            return start.formatted(fmt)
        case let (nil, end?):
            return end.formatted(fmt)
        default:
            return nil
        }
    }
}
