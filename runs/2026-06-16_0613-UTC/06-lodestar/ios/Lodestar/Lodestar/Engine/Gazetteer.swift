import Foundation

/// A bundled city for picking an observing location without any location permission.
struct GazetteerCity: Identifiable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double   // east positive
    /// IANA time-zone identifier for correct local rise/set.
    let timeZoneID: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }
    var displayName: String { "\(name), \(country)" }
}

/// ~70 world cities spanning all continents and both hemispheres.
enum Gazetteer {
    static let cities: [GazetteerCity] = [
        c("city.london", "London", "UK", 51.5074, -0.1278, "Europe/London"),
        c("city.paris", "Paris", "France", 48.8566, 2.3522, "Europe/Paris"),
        c("city.berlin", "Berlin", "Germany", 52.5200, 13.4050, "Europe/Berlin"),
        c("city.madrid", "Madrid", "Spain", 40.4168, -3.7038, "Europe/Madrid"),
        c("city.rome", "Rome", "Italy", 41.9028, 12.4964, "Europe/Rome"),
        c("city.amsterdam", "Amsterdam", "Netherlands", 52.3676, 4.9041, "Europe/Amsterdam"),
        c("city.vienna", "Vienna", "Austria", 48.2082, 16.3738, "Europe/Vienna"),
        c("city.athens", "Athens", "Greece", 37.9838, 23.7275, "Europe/Athens"),
        c("city.lisbon", "Lisbon", "Portugal", 38.7223, -9.1393, "Europe/Lisbon"),
        c("city.stockholm", "Stockholm", "Sweden", 59.3293, 18.0686, "Europe/Stockholm"),
        c("city.oslo", "Oslo", "Norway", 59.9139, 10.7522, "Europe/Oslo"),
        c("city.helsinki", "Helsinki", "Finland", 60.1699, 24.9384, "Europe/Helsinki"),
        c("city.reykjavik", "Reykjavík", "Iceland", 64.1466, -21.9426, "Atlantic/Reykjavik"),
        c("city.dublin", "Dublin", "Ireland", 53.3498, -6.2603, "Europe/Dublin"),
        c("city.moscow", "Moscow", "Russia", 55.7558, 37.6173, "Europe/Moscow"),
        c("city.istanbul", "Istanbul", "Türkiye", 41.0082, 28.9784, "Europe/Istanbul"),
        c("city.warsaw", "Warsaw", "Poland", 52.2297, 21.0122, "Europe/Warsaw"),
        c("city.zurich", "Zürich", "Switzerland", 47.3769, 8.5417, "Europe/Zurich"),

        c("city.newyork", "New York", "USA", 40.7128, -74.0060, "America/New_York"),
        c("city.losangeles", "Los Angeles", "USA", 34.0522, -118.2437, "America/Los_Angeles"),
        c("city.chicago", "Chicago", "USA", 41.8781, -87.6298, "America/Chicago"),
        c("city.denver", "Denver", "USA", 39.7392, -104.9903, "America/Denver"),
        c("city.seattle", "Seattle", "USA", 47.6062, -122.3321, "America/Los_Angeles"),
        c("city.miami", "Miami", "USA", 25.7617, -80.1918, "America/New_York"),
        c("city.phoenix", "Phoenix", "USA", 33.4484, -112.0740, "America/Phoenix"),
        c("city.honolulu", "Honolulu", "USA", 21.3069, -157.8583, "Pacific/Honolulu"),
        c("city.anchorage", "Anchorage", "USA", 61.2181, -149.9003, "America/Anchorage"),
        c("city.toronto", "Toronto", "Canada", 43.6532, -79.3832, "America/Toronto"),
        c("city.vancouver", "Vancouver", "Canada", 49.2827, -123.1207, "America/Vancouver"),
        c("city.mexicocity", "Mexico City", "Mexico", 19.4326, -99.1332, "America/Mexico_City"),
        c("city.bogota", "Bogotá", "Colombia", 4.7110, -74.0721, "America/Bogota"),
        c("city.lima", "Lima", "Peru", -12.0464, -77.0428, "America/Lima"),
        c("city.santiago", "Santiago", "Chile", -33.4489, -70.6693, "America/Santiago"),
        c("city.buenosaires", "Buenos Aires", "Argentina", -34.6037, -58.3816, "America/Argentina/Buenos_Aires"),
        c("city.saopaulo", "São Paulo", "Brazil", -23.5505, -46.6333, "America/Sao_Paulo"),
        c("city.rio", "Rio de Janeiro", "Brazil", -22.9068, -43.1729, "America/Sao_Paulo"),

        c("city.cairo", "Cairo", "Egypt", 30.0444, 31.2357, "Africa/Cairo"),
        c("city.lagos", "Lagos", "Nigeria", 6.5244, 3.3792, "Africa/Lagos"),
        c("city.nairobi", "Nairobi", "Kenya", -1.2921, 36.8219, "Africa/Nairobi"),
        c("city.capetown", "Cape Town", "South Africa", -33.9249, 18.4241, "Africa/Johannesburg"),
        c("city.johannesburg", "Johannesburg", "South Africa", -26.2041, 28.0473, "Africa/Johannesburg"),
        c("city.casablanca", "Casablanca", "Morocco", 33.5731, -7.5898, "Africa/Casablanca"),
        c("city.addis", "Addis Ababa", "Ethiopia", 9.0300, 38.7400, "Africa/Addis_Ababa"),

        c("city.dubai", "Dubai", "UAE", 25.2048, 55.2708, "Asia/Dubai"),
        c("city.telaviv", "Tel Aviv", "Israel", 32.0853, 34.7818, "Asia/Jerusalem"),
        c("city.riyadh", "Riyadh", "Saudi Arabia", 24.7136, 46.6753, "Asia/Riyadh"),
        c("city.tehran", "Tehran", "Iran", 35.6892, 51.3890, "Asia/Tehran"),
        c("city.delhi", "Delhi", "India", 28.6139, 77.2090, "Asia/Kolkata"),
        c("city.mumbai", "Mumbai", "India", 19.0760, 72.8777, "Asia/Kolkata"),
        c("city.bangalore", "Bengaluru", "India", 12.9716, 77.5946, "Asia/Kolkata"),
        c("city.karachi", "Karachi", "Pakistan", 24.8607, 67.0011, "Asia/Karachi"),
        c("city.dhaka", "Dhaka", "Bangladesh", 23.8103, 90.4125, "Asia/Dhaka"),
        c("city.bangkok", "Bangkok", "Thailand", 13.7563, 100.5018, "Asia/Bangkok"),
        c("city.singapore", "Singapore", "Singapore", 1.3521, 103.8198, "Asia/Singapore"),
        c("city.jakarta", "Jakarta", "Indonesia", -6.2088, 106.8456, "Asia/Jakarta"),
        c("city.manila", "Manila", "Philippines", 14.5995, 120.9842, "Asia/Manila"),
        c("city.hanoi", "Hanoi", "Vietnam", 21.0278, 105.8342, "Asia/Ho_Chi_Minh"),
        c("city.kualalumpur", "Kuala Lumpur", "Malaysia", 3.1390, 101.6869, "Asia/Kuala_Lumpur"),
        c("city.beijing", "Beijing", "China", 39.9042, 116.4074, "Asia/Shanghai"),
        c("city.shanghai", "Shanghai", "China", 31.2304, 121.4737, "Asia/Shanghai"),
        c("city.hongkong", "Hong Kong", "China", 22.3193, 114.1694, "Asia/Hong_Kong"),
        c("city.taipei", "Taipei", "Taiwan", 25.0330, 121.5654, "Asia/Taipei"),
        c("city.seoul", "Seoul", "South Korea", 37.5665, 126.9780, "Asia/Seoul"),
        c("city.tokyo", "Tokyo", "Japan", 35.6762, 139.6503, "Asia/Tokyo"),
        c("city.osaka", "Osaka", "Japan", 34.6937, 135.5023, "Asia/Tokyo"),

        c("city.sydney", "Sydney", "Australia", -33.8688, 151.2093, "Australia/Sydney"),
        c("city.melbourne", "Melbourne", "Australia", -37.8136, 144.9631, "Australia/Melbourne"),
        c("city.perth", "Perth", "Australia", -31.9505, 115.8605, "Australia/Perth"),
        c("city.brisbane", "Brisbane", "Australia", -27.4698, 153.0251, "Australia/Brisbane"),
        c("city.auckland", "Auckland", "New Zealand", -36.8485, 174.7633, "Pacific/Auckland"),
        c("city.suva", "Suva", "Fiji", -18.1248, 178.4501, "Pacific/Fiji")
    ]

    static let byID: [String: GazetteerCity] = {
        Dictionary(uniqueKeysWithValues: cities.map { ($0.id, $0) })
    }()

    private static func c(_ id: String, _ name: String, _ country: String,
                          _ lat: Double, _ lon: Double, _ tz: String) -> GazetteerCity {
        GazetteerCity(id: id, name: name, country: country, latitude: lat, longitude: lon, timeZoneID: tz)
    }
}
