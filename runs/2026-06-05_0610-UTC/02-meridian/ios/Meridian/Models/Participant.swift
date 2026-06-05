import Foundation

/// A person/place in the meeting, identified by an IANA timezone.
struct Participant: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var city: String
    var tzIdentifier: String

    var timeZone: TimeZone { TimeZone(identifier: tzIdentifier) ?? .current }

    /// Offset from UTC in minutes for the given instant (handles DST).
    func offsetMinutes(_ date: Date) -> Int {
        timeZone.secondsFromGMT(for: date) / 60
    }
}

/// A curated catalog of common meeting cities.
enum TimeZoneCatalog {
    static let cities: [(city: String, tz: String)] = [
        ("San Francisco", "America/Los_Angeles"),
        ("Denver", "America/Denver"),
        ("Chicago", "America/Chicago"),
        ("New York", "America/New_York"),
        ("São Paulo", "America/Sao_Paulo"),
        ("London", "Europe/London"),
        ("Lagos", "Africa/Lagos"),
        ("Berlin", "Europe/Berlin"),
        ("Cape Town", "Africa/Johannesburg"),
        ("Dubai", "Asia/Dubai"),
        ("Mumbai", "Asia/Kolkata"),
        ("Singapore", "Asia/Singapore"),
        ("Beijing", "Asia/Shanghai"),
        ("Tokyo", "Asia/Tokyo"),
        ("Sydney", "Australia/Sydney"),
        ("Auckland", "Pacific/Auckland"),
    ]
}
