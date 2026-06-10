import Foundation

struct City: Identifiable, Hashable {
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double      // east-positive
    let timeZoneID: String

    var id: String { "\(name)-\(country)" }
    var label: String { "\(name), \(country)" }
}

/// A compact world-city gazetteer for birth places. Coordinates are city
/// centers; for astrology, anything within ~50 km is indistinguishable.
enum CityCatalog {

    static func search(_ query: String) -> [City] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(q) || $0.country.localizedCaseInsensitiveContains(q)
        }
    }

    static let all: [City] = [
        City(name: "New York", country: "United States", latitude: 40.71, longitude: -74.01, timeZoneID: "America/New_York"),
        City(name: "Los Angeles", country: "United States", latitude: 34.05, longitude: -118.24, timeZoneID: "America/Los_Angeles"),
        City(name: "Chicago", country: "United States", latitude: 41.88, longitude: -87.63, timeZoneID: "America/Chicago"),
        City(name: "Houston", country: "United States", latitude: 29.76, longitude: -95.37, timeZoneID: "America/Chicago"),
        City(name: "Phoenix", country: "United States", latitude: 33.45, longitude: -112.07, timeZoneID: "America/Phoenix"),
        City(name: "Denver", country: "United States", latitude: 39.74, longitude: -104.99, timeZoneID: "America/Denver"),
        City(name: "Seattle", country: "United States", latitude: 47.61, longitude: -122.33, timeZoneID: "America/Los_Angeles"),
        City(name: "Miami", country: "United States", latitude: 25.76, longitude: -80.19, timeZoneID: "America/New_York"),
        City(name: "Atlanta", country: "United States", latitude: 33.75, longitude: -84.39, timeZoneID: "America/New_York"),
        City(name: "Boston", country: "United States", latitude: 42.36, longitude: -71.06, timeZoneID: "America/New_York"),
        City(name: "San Francisco", country: "United States", latitude: 37.77, longitude: -122.42, timeZoneID: "America/Los_Angeles"),
        City(name: "Honolulu", country: "United States", latitude: 21.31, longitude: -157.86, timeZoneID: "Pacific/Honolulu"),
        City(name: "Anchorage", country: "United States", latitude: 61.22, longitude: -149.90, timeZoneID: "America/Anchorage"),
        City(name: "Toronto", country: "Canada", latitude: 43.65, longitude: -79.38, timeZoneID: "America/Toronto"),
        City(name: "Vancouver", country: "Canada", latitude: 49.28, longitude: -123.12, timeZoneID: "America/Vancouver"),
        City(name: "Montreal", country: "Canada", latitude: 45.50, longitude: -73.57, timeZoneID: "America/Toronto"),
        City(name: "Mexico City", country: "Mexico", latitude: 19.43, longitude: -99.13, timeZoneID: "America/Mexico_City"),
        City(name: "São Paulo", country: "Brazil", latitude: -23.55, longitude: -46.63, timeZoneID: "America/Sao_Paulo"),
        City(name: "Rio de Janeiro", country: "Brazil", latitude: -22.91, longitude: -43.17, timeZoneID: "America/Sao_Paulo"),
        City(name: "Buenos Aires", country: "Argentina", latitude: -34.60, longitude: -58.38, timeZoneID: "America/Argentina/Buenos_Aires"),
        City(name: "Santiago", country: "Chile", latitude: -33.45, longitude: -70.67, timeZoneID: "America/Santiago"),
        City(name: "Lima", country: "Peru", latitude: -12.05, longitude: -77.04, timeZoneID: "America/Lima"),
        City(name: "Bogotá", country: "Colombia", latitude: 4.71, longitude: -74.07, timeZoneID: "America/Bogota"),
        City(name: "London", country: "United Kingdom", latitude: 51.51, longitude: -0.13, timeZoneID: "Europe/London"),
        City(name: "Manchester", country: "United Kingdom", latitude: 53.48, longitude: -2.24, timeZoneID: "Europe/London"),
        City(name: "Edinburgh", country: "United Kingdom", latitude: 55.95, longitude: -3.19, timeZoneID: "Europe/London"),
        City(name: "Dublin", country: "Ireland", latitude: 53.35, longitude: -6.26, timeZoneID: "Europe/Dublin"),
        City(name: "Paris", country: "France", latitude: 48.86, longitude: 2.35, timeZoneID: "Europe/Paris"),
        City(name: "Berlin", country: "Germany", latitude: 52.52, longitude: 13.41, timeZoneID: "Europe/Berlin"),
        City(name: "Munich", country: "Germany", latitude: 48.14, longitude: 11.58, timeZoneID: "Europe/Berlin"),
        City(name: "Madrid", country: "Spain", latitude: 40.42, longitude: -3.70, timeZoneID: "Europe/Madrid"),
        City(name: "Barcelona", country: "Spain", latitude: 41.39, longitude: 2.17, timeZoneID: "Europe/Madrid"),
        City(name: "Rome", country: "Italy", latitude: 41.90, longitude: 12.50, timeZoneID: "Europe/Rome"),
        City(name: "Milan", country: "Italy", latitude: 45.46, longitude: 9.19, timeZoneID: "Europe/Rome"),
        City(name: "Amsterdam", country: "Netherlands", latitude: 52.37, longitude: 4.90, timeZoneID: "Europe/Amsterdam"),
        City(name: "Brussels", country: "Belgium", latitude: 50.85, longitude: 4.35, timeZoneID: "Europe/Brussels"),
        City(name: "Zurich", country: "Switzerland", latitude: 47.38, longitude: 8.54, timeZoneID: "Europe/Zurich"),
        City(name: "Vienna", country: "Austria", latitude: 48.21, longitude: 16.37, timeZoneID: "Europe/Vienna"),
        City(name: "Prague", country: "Czechia", latitude: 50.08, longitude: 14.44, timeZoneID: "Europe/Prague"),
        City(name: "Warsaw", country: "Poland", latitude: 52.23, longitude: 21.01, timeZoneID: "Europe/Warsaw"),
        City(name: "Stockholm", country: "Sweden", latitude: 59.33, longitude: 18.07, timeZoneID: "Europe/Stockholm"),
        City(name: "Oslo", country: "Norway", latitude: 59.91, longitude: 10.75, timeZoneID: "Europe/Oslo"),
        City(name: "Copenhagen", country: "Denmark", latitude: 55.68, longitude: 12.57, timeZoneID: "Europe/Copenhagen"),
        City(name: "Helsinki", country: "Finland", latitude: 60.17, longitude: 24.94, timeZoneID: "Europe/Helsinki"),
        City(name: "Lisbon", country: "Portugal", latitude: 38.72, longitude: -9.14, timeZoneID: "Europe/Lisbon"),
        City(name: "Athens", country: "Greece", latitude: 37.98, longitude: 23.73, timeZoneID: "Europe/Athens"),
        City(name: "Istanbul", country: "Türkiye", latitude: 41.01, longitude: 28.98, timeZoneID: "Europe/Istanbul"),
        City(name: "Moscow", country: "Russia", latitude: 55.76, longitude: 37.62, timeZoneID: "Europe/Moscow"),
        City(name: "Kyiv", country: "Ukraine", latitude: 50.45, longitude: 30.52, timeZoneID: "Europe/Kyiv"),
        City(name: "Bucharest", country: "Romania", latitude: 44.43, longitude: 26.10, timeZoneID: "Europe/Bucharest"),
        City(name: "Budapest", country: "Hungary", latitude: 47.50, longitude: 19.04, timeZoneID: "Europe/Budapest"),
        City(name: "Cairo", country: "Egypt", latitude: 30.04, longitude: 31.24, timeZoneID: "Africa/Cairo"),
        City(name: "Lagos", country: "Nigeria", latitude: 6.52, longitude: 3.38, timeZoneID: "Africa/Lagos"),
        City(name: "Nairobi", country: "Kenya", latitude: -1.29, longitude: 36.82, timeZoneID: "Africa/Nairobi"),
        City(name: "Johannesburg", country: "South Africa", latitude: -26.20, longitude: 28.05, timeZoneID: "Africa/Johannesburg"),
        City(name: "Cape Town", country: "South Africa", latitude: -33.92, longitude: 18.42, timeZoneID: "Africa/Johannesburg"),
        City(name: "Casablanca", country: "Morocco", latitude: 33.57, longitude: -7.59, timeZoneID: "Africa/Casablanca"),
        City(name: "Dubai", country: "United Arab Emirates", latitude: 25.20, longitude: 55.27, timeZoneID: "Asia/Dubai"),
        City(name: "Tel Aviv", country: "Israel", latitude: 32.09, longitude: 34.78, timeZoneID: "Asia/Jerusalem"),
        City(name: "Riyadh", country: "Saudi Arabia", latitude: 24.71, longitude: 46.68, timeZoneID: "Asia/Riyadh"),
        City(name: "Mumbai", country: "India", latitude: 19.08, longitude: 72.88, timeZoneID: "Asia/Kolkata"),
        City(name: "Delhi", country: "India", latitude: 28.61, longitude: 77.21, timeZoneID: "Asia/Kolkata"),
        City(name: "Bengaluru", country: "India", latitude: 12.97, longitude: 77.59, timeZoneID: "Asia/Kolkata"),
        City(name: "Karachi", country: "Pakistan", latitude: 24.86, longitude: 67.01, timeZoneID: "Asia/Karachi"),
        City(name: "Dhaka", country: "Bangladesh", latitude: 23.81, longitude: 90.41, timeZoneID: "Asia/Dhaka"),
        City(name: "Bangkok", country: "Thailand", latitude: 13.76, longitude: 100.50, timeZoneID: "Asia/Bangkok"),
        City(name: "Singapore", country: "Singapore", latitude: 1.35, longitude: 103.82, timeZoneID: "Asia/Singapore"),
        City(name: "Kuala Lumpur", country: "Malaysia", latitude: 3.14, longitude: 101.69, timeZoneID: "Asia/Kuala_Lumpur"),
        City(name: "Jakarta", country: "Indonesia", latitude: -6.21, longitude: 106.85, timeZoneID: "Asia/Jakarta"),
        City(name: "Manila", country: "Philippines", latitude: 14.60, longitude: 120.98, timeZoneID: "Asia/Manila"),
        City(name: "Ho Chi Minh City", country: "Vietnam", latitude: 10.82, longitude: 106.63, timeZoneID: "Asia/Ho_Chi_Minh"),
        City(name: "Hong Kong", country: "China", latitude: 22.32, longitude: 114.17, timeZoneID: "Asia/Hong_Kong"),
        City(name: "Shanghai", country: "China", latitude: 31.23, longitude: 121.47, timeZoneID: "Asia/Shanghai"),
        City(name: "Beijing", country: "China", latitude: 39.90, longitude: 116.41, timeZoneID: "Asia/Shanghai"),
        City(name: "Taipei", country: "Taiwan", latitude: 25.03, longitude: 121.57, timeZoneID: "Asia/Taipei"),
        City(name: "Seoul", country: "South Korea", latitude: 37.57, longitude: 126.98, timeZoneID: "Asia/Seoul"),
        City(name: "Tokyo", country: "Japan", latitude: 35.68, longitude: 139.69, timeZoneID: "Asia/Tokyo"),
        City(name: "Osaka", country: "Japan", latitude: 34.69, longitude: 135.50, timeZoneID: "Asia/Tokyo"),
        City(name: "Sydney", country: "Australia", latitude: -33.87, longitude: 151.21, timeZoneID: "Australia/Sydney"),
        City(name: "Melbourne", country: "Australia", latitude: -37.81, longitude: 144.96, timeZoneID: "Australia/Melbourne"),
        City(name: "Brisbane", country: "Australia", latitude: -27.47, longitude: 153.03, timeZoneID: "Australia/Brisbane"),
        City(name: "Perth", country: "Australia", latitude: -31.95, longitude: 115.86, timeZoneID: "Australia/Perth"),
        City(name: "Auckland", country: "New Zealand", latitude: -36.85, longitude: 174.76, timeZoneID: "Pacific/Auckland"),
        City(name: "Wellington", country: "New Zealand", latitude: -41.29, longitude: 174.78, timeZoneID: "Pacific/Auckland")
    ]
}
