import Foundation
import SwiftData

/// One person's birth data. The chart itself is always computed fresh from
/// these values — nothing interpretive is stored.
@Model
final class ChartProfile {
    var name: String
    var birthDate: Date          // exact UT instant
    var timeZoneID: String       // zone the birth time was entered in
    var latitude: Double
    var longitude: Double        // east-positive
    var placeName: String
    var timeKnown: Bool
    var isPrimary: Bool
    var createdAt: Date

    init(name: String, birthDate: Date, timeZoneID: String,
         latitude: Double, longitude: Double, placeName: String,
         timeKnown: Bool, isPrimary: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.birthDate = birthDate
        self.timeZoneID = timeZoneID
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.timeKnown = timeKnown
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }

    var birthDescription: String {
        let fmt = DateFormatter()
        fmt.timeZone = timeZone
        fmt.dateStyle = .long
        fmt.timeStyle = timeKnown ? .short : .none
        return fmt.string(from: birthDate)
    }
}
