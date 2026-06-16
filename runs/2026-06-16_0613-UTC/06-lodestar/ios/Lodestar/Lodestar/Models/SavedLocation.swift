import Foundation
import SwiftData

/// A user-saved observing location (persisted across launches).
@Model
final class SavedLocation {
    /// Stable identifier — gazetteer id (e.g. "city.london") or a generated UUID for custom.
    @Attribute(.unique) var locationID: String
    var name: String
    var latitude: Double
    var longitude: Double
    var timeZoneID: String
    var createdAt: Date

    init(locationID: String, name: String, latitude: Double, longitude: Double, timeZoneID: String, createdAt: Date = .now) {
        self.locationID = locationID
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneID = timeZoneID
        self.createdAt = createdAt
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
}
