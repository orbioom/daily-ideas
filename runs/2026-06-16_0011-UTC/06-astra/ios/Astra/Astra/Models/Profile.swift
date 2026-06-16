import Foundation
import SwiftData

/// A saved birth chart's source data. Placements are computed on the fly via
/// `Ephemeris` from these fields — never persisted, so the math stays the
/// single source of truth.
@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Birth moment in UTC. Combined with `tzOffsetHours` this recovers local birth time.
    var birthDate: Date
    /// When false, the exact time is unknown: houses/Ascendant are hidden.
    var hasExactTime: Bool
    var latitude: Double
    var longitude: Double
    var locationName: String
    /// The birth location's UTC offset in hours (e.g. -5 for US East in winter).
    var tzOffsetHours: Double
    var isPrimary: Bool
    /// Drives a stable accent tint for this profile in lists/avatars.
    var colorSeed: Int
    var createdDate: Date

    init(name: String,
         birthDate: Date,
         hasExactTime: Bool,
         latitude: Double,
         longitude: Double,
         locationName: String,
         tzOffsetHours: Double,
         isPrimary: Bool = false,
         colorSeed: Int = 0,
         createdDate: Date = .now) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.hasExactTime = hasExactTime
        self.latitude = min(max(latitude, -89.9), 89.9)
        self.longitude = min(max(longitude, -180), 180)
        self.locationName = locationName
        self.tzOffsetHours = min(max(tzOffsetHours, -14), 14)
        self.isPrimary = isPrimary
        self.colorSeed = colorSeed
        self.createdDate = createdDate
    }

    /// First initial for an avatar, guarded for empty names.
    var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }
}
