import Foundation

/// A location with a known latitude/longitude and (optional) timezone.
struct Place: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var lat: Double
    var lon: Double
    var tzIdentifier: String?     // nil -> device's current timezone

    var timeZone: TimeZone {
        tzIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    func tzOffsetHours(_ date: Date) -> Double {
        Double(timeZone.secondsFromGMT(for: date)) / 3600.0
    }

    static func == (a: Place, b: Place) -> Bool {
        a.name == b.name && a.lat == b.lat && a.lon == b.lon
    }

    static let presets: [Place] = [
        Place(name: "London", lat: 51.5074, lon: -0.1278, tzIdentifier: "Europe/London"),
        Place(name: "New York", lat: 40.7128, lon: -74.0060, tzIdentifier: "America/New_York"),
        Place(name: "San Francisco", lat: 37.7749, lon: -122.4194, tzIdentifier: "America/Los_Angeles"),
        Place(name: "Reykjavík", lat: 64.1466, lon: -21.9426, tzIdentifier: "Atlantic/Reykjavik"),
        Place(name: "Tokyo", lat: 35.6762, lon: 139.6503, tzIdentifier: "Asia/Tokyo"),
        Place(name: "Sydney", lat: -33.8688, lon: 151.2093, tzIdentifier: "Australia/Sydney"),
        Place(name: "Cape Town", lat: -33.9249, lon: 18.4241, tzIdentifier: "Africa/Johannesburg"),
        Place(name: "Tromsø", lat: 69.6492, lon: 18.9553, tzIdentifier: "Europe/Oslo"),
    ]
    static let london = presets[0]
}
