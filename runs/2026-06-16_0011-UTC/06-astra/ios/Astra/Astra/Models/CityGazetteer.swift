import Foundation

/// A built-in birth-city entry so Astra never needs a location permission.
/// `tzOffset` is the location's *standard* UTC offset in hours. (Astrology fixes a
/// birth moment to its local clock time; this offset converts it to UTC for the
/// ephemeris. Historical DST edge cases can be refined with the manual offset field.)
struct GazetteerCity: Identifiable, Hashable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let tzOffset: Double

    var displayName: String { "\(name), \(country)" }
}

enum CityGazetteer {
    static func city(id: String) -> GazetteerCity? {
        cities.first { $0.id == id }
    }

    static let defaultCityID = "london"

    static func search(_ query: String) -> [GazetteerCity] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return cities }
        return cities.filter {
            $0.name.lowercased().contains(q) || $0.country.lowercased().contains(q)
        }
    }

    static let cities: [GazetteerCity] = [
        // North America
        GazetteerCity(id: "newyork", name: "New York", country: "USA", latitude: 40.7128, longitude: -74.0060, tzOffset: -5),
        GazetteerCity(id: "losangeles", name: "Los Angeles", country: "USA", latitude: 34.0522, longitude: -118.2437, tzOffset: -8),
        GazetteerCity(id: "chicago", name: "Chicago", country: "USA", latitude: 41.8781, longitude: -87.6298, tzOffset: -6),
        GazetteerCity(id: "houston", name: "Houston", country: "USA", latitude: 29.7604, longitude: -95.3698, tzOffset: -6),
        GazetteerCity(id: "phoenix", name: "Phoenix", country: "USA", latitude: 33.4484, longitude: -112.0740, tzOffset: -7),
        GazetteerCity(id: "denver", name: "Denver", country: "USA", latitude: 39.7392, longitude: -104.9903, tzOffset: -7),
        GazetteerCity(id: "seattle", name: "Seattle", country: "USA", latitude: 47.6062, longitude: -122.3321, tzOffset: -8),
        GazetteerCity(id: "sanfrancisco", name: "San Francisco", country: "USA", latitude: 37.7749, longitude: -122.4194, tzOffset: -8),
        GazetteerCity(id: "miami", name: "Miami", country: "USA", latitude: 25.7617, longitude: -80.1918, tzOffset: -5),
        GazetteerCity(id: "boston", name: "Boston", country: "USA", latitude: 42.3601, longitude: -71.0589, tzOffset: -5),
        GazetteerCity(id: "atlanta", name: "Atlanta", country: "USA", latitude: 33.7490, longitude: -84.3880, tzOffset: -5),
        GazetteerCity(id: "honolulu", name: "Honolulu", country: "USA", latitude: 21.3069, longitude: -157.8583, tzOffset: -10),
        GazetteerCity(id: "toronto", name: "Toronto", country: "Canada", latitude: 43.6532, longitude: -79.3832, tzOffset: -5),
        GazetteerCity(id: "vancouver", name: "Vancouver", country: "Canada", latitude: 49.2827, longitude: -123.1207, tzOffset: -8),
        GazetteerCity(id: "montreal", name: "Montréal", country: "Canada", latitude: 45.5019, longitude: -73.5674, tzOffset: -5),
        GazetteerCity(id: "mexicocity", name: "Mexico City", country: "Mexico", latitude: 19.4326, longitude: -99.1332, tzOffset: -6),

        // South America
        GazetteerCity(id: "saopaulo", name: "São Paulo", country: "Brazil", latitude: -23.5505, longitude: -46.6333, tzOffset: -3),
        GazetteerCity(id: "riodejaneiro", name: "Rio de Janeiro", country: "Brazil", latitude: -22.9068, longitude: -43.1729, tzOffset: -3),
        GazetteerCity(id: "buenosaires", name: "Buenos Aires", country: "Argentina", latitude: -34.6037, longitude: -58.3816, tzOffset: -3),
        GazetteerCity(id: "lima", name: "Lima", country: "Peru", latitude: -12.0464, longitude: -77.0428, tzOffset: -5),
        GazetteerCity(id: "bogota", name: "Bogotá", country: "Colombia", latitude: 4.7110, longitude: -74.0721, tzOffset: -5),
        GazetteerCity(id: "santiago", name: "Santiago", country: "Chile", latitude: -33.4489, longitude: -70.6693, tzOffset: -4),

        // Europe
        GazetteerCity(id: "london", name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278, tzOffset: 0),
        GazetteerCity(id: "dublin", name: "Dublin", country: "Ireland", latitude: 53.3498, longitude: -6.2603, tzOffset: 0),
        GazetteerCity(id: "paris", name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, tzOffset: 1),
        GazetteerCity(id: "madrid", name: "Madrid", country: "Spain", latitude: 40.4168, longitude: -3.7038, tzOffset: 1),
        GazetteerCity(id: "barcelona", name: "Barcelona", country: "Spain", latitude: 41.3874, longitude: 2.1686, tzOffset: 1),
        GazetteerCity(id: "lisbon", name: "Lisbon", country: "Portugal", latitude: 38.7223, longitude: -9.1393, tzOffset: 0),
        GazetteerCity(id: "berlin", name: "Berlin", country: "Germany", latitude: 52.5200, longitude: 13.4050, tzOffset: 1),
        GazetteerCity(id: "munich", name: "Munich", country: "Germany", latitude: 48.1351, longitude: 11.5820, tzOffset: 1),
        GazetteerCity(id: "rome", name: "Rome", country: "Italy", latitude: 41.9028, longitude: 12.4964, tzOffset: 1),
        GazetteerCity(id: "milan", name: "Milan", country: "Italy", latitude: 45.4642, longitude: 9.1900, tzOffset: 1),
        GazetteerCity(id: "amsterdam", name: "Amsterdam", country: "Netherlands", latitude: 52.3676, longitude: 4.9041, tzOffset: 1),
        GazetteerCity(id: "brussels", name: "Brussels", country: "Belgium", latitude: 50.8503, longitude: 4.3517, tzOffset: 1),
        GazetteerCity(id: "zurich", name: "Zurich", country: "Switzerland", latitude: 47.3769, longitude: 8.5417, tzOffset: 1),
        GazetteerCity(id: "vienna", name: "Vienna", country: "Austria", latitude: 48.2082, longitude: 16.3738, tzOffset: 1),
        GazetteerCity(id: "stockholm", name: "Stockholm", country: "Sweden", latitude: 59.3293, longitude: 18.0686, tzOffset: 1),
        GazetteerCity(id: "copenhagen", name: "Copenhagen", country: "Denmark", latitude: 55.6761, longitude: 12.5683, tzOffset: 1),
        GazetteerCity(id: "oslo", name: "Oslo", country: "Norway", latitude: 59.9139, longitude: 10.7522, tzOffset: 1),
        GazetteerCity(id: "athens", name: "Athens", country: "Greece", latitude: 37.9838, longitude: 23.7275, tzOffset: 2),
        GazetteerCity(id: "warsaw", name: "Warsaw", country: "Poland", latitude: 52.2297, longitude: 21.0122, tzOffset: 1),
        GazetteerCity(id: "moscow", name: "Moscow", country: "Russia", latitude: 55.7558, longitude: 37.6173, tzOffset: 3),
        GazetteerCity(id: "istanbul", name: "Istanbul", country: "Türkiye", latitude: 41.0082, longitude: 28.9784, tzOffset: 3),

        // Middle East & Africa
        GazetteerCity(id: "dubai", name: "Dubai", country: "UAE", latitude: 25.2048, longitude: 55.2708, tzOffset: 4),
        GazetteerCity(id: "telaviv", name: "Tel Aviv", country: "Israel", latitude: 32.0853, longitude: 34.7818, tzOffset: 2),
        GazetteerCity(id: "riyadh", name: "Riyadh", country: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753, tzOffset: 3),
        GazetteerCity(id: "tehran", name: "Tehran", country: "Iran", latitude: 35.6892, longitude: 51.3890, tzOffset: 3.5),
        GazetteerCity(id: "cairo", name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357, tzOffset: 2),
        GazetteerCity(id: "lagos", name: "Lagos", country: "Nigeria", latitude: 6.5244, longitude: 3.3792, tzOffset: 1),
        GazetteerCity(id: "nairobi", name: "Nairobi", country: "Kenya", latitude: -1.2921, longitude: 36.8219, tzOffset: 3),
        GazetteerCity(id: "johannesburg", name: "Johannesburg", country: "South Africa", latitude: -26.2041, longitude: 28.0473, tzOffset: 2),
        GazetteerCity(id: "casablanca", name: "Casablanca", country: "Morocco", latitude: 33.5731, longitude: -7.5898, tzOffset: 0),

        // Asia
        GazetteerCity(id: "delhi", name: "Delhi", country: "India", latitude: 28.7041, longitude: 77.1025, tzOffset: 5.5),
        GazetteerCity(id: "mumbai", name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777, tzOffset: 5.5),
        GazetteerCity(id: "bangalore", name: "Bangalore", country: "India", latitude: 12.9716, longitude: 77.5946, tzOffset: 5.5),
        GazetteerCity(id: "karachi", name: "Karachi", country: "Pakistan", latitude: 24.8607, longitude: 67.0011, tzOffset: 5),
        GazetteerCity(id: "dhaka", name: "Dhaka", country: "Bangladesh", latitude: 23.8103, longitude: 90.4125, tzOffset: 6),
        GazetteerCity(id: "bangkok", name: "Bangkok", country: "Thailand", latitude: 13.7563, longitude: 100.5018, tzOffset: 7),
        GazetteerCity(id: "jakarta", name: "Jakarta", country: "Indonesia", latitude: -6.2088, longitude: 106.8456, tzOffset: 7),
        GazetteerCity(id: "singapore", name: "Singapore", country: "Singapore", latitude: 1.3521, longitude: 103.8198, tzOffset: 8),
        GazetteerCity(id: "kualalumpur", name: "Kuala Lumpur", country: "Malaysia", latitude: 3.1390, longitude: 101.6869, tzOffset: 8),
        GazetteerCity(id: "manila", name: "Manila", country: "Philippines", latitude: 14.5995, longitude: 120.9842, tzOffset: 8),
        GazetteerCity(id: "hongkong", name: "Hong Kong", country: "China", latitude: 22.3193, longitude: 114.1694, tzOffset: 8),
        GazetteerCity(id: "beijing", name: "Beijing", country: "China", latitude: 39.9042, longitude: 116.4074, tzOffset: 8),
        GazetteerCity(id: "shanghai", name: "Shanghai", country: "China", latitude: 31.2304, longitude: 121.4737, tzOffset: 8),
        GazetteerCity(id: "seoul", name: "Seoul", country: "South Korea", latitude: 37.5665, longitude: 126.9780, tzOffset: 9),
        GazetteerCity(id: "tokyo", name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503, tzOffset: 9),
        GazetteerCity(id: "osaka", name: "Osaka", country: "Japan", latitude: 34.6937, longitude: 135.5023, tzOffset: 9),

        // Oceania
        GazetteerCity(id: "sydney", name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093, tzOffset: 10),
        GazetteerCity(id: "melbourne", name: "Melbourne", country: "Australia", latitude: -37.8136, longitude: 144.9631, tzOffset: 10),
        GazetteerCity(id: "perth", name: "Perth", country: "Australia", latitude: -31.9505, longitude: 115.8605, tzOffset: 8),
        GazetteerCity(id: "auckland", name: "Auckland", country: "New Zealand", latitude: -36.8509, longitude: 174.7645, tzOffset: 12)
    ]
}
