import Foundation

/// Built-in gazetteer so Mihrab never needs a location permission.
/// Coordinates are city centers; time zones are IANA identifiers so DST is
/// handled correctly by Foundation for any date.
struct City: Identifiable, Hashable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timeZoneID: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
    var displayName: String { "\(name), \(country)" }
}

enum Gazetteer {
    static func city(id: String) -> City? {
        cities.first { $0.id == id }
    }

    static let defaultCityID = "london"

    static let cities: [City] = [
        // Middle East & Gulf
        City(id: "makkah", name: "Makkah", country: "Saudi Arabia", latitude: 21.4225, longitude: 39.8262, timeZoneID: "Asia/Riyadh"),
        City(id: "madinah", name: "Madinah", country: "Saudi Arabia", latitude: 24.4672, longitude: 39.6111, timeZoneID: "Asia/Riyadh"),
        City(id: "riyadh", name: "Riyadh", country: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753, timeZoneID: "Asia/Riyadh"),
        City(id: "jeddah", name: "Jeddah", country: "Saudi Arabia", latitude: 21.4858, longitude: 39.1925, timeZoneID: "Asia/Riyadh"),
        City(id: "dubai", name: "Dubai", country: "UAE", latitude: 25.2048, longitude: 55.2708, timeZoneID: "Asia/Dubai"),
        City(id: "abudhabi", name: "Abu Dhabi", country: "UAE", latitude: 24.4539, longitude: 54.3773, timeZoneID: "Asia/Dubai"),
        City(id: "doha", name: "Doha", country: "Qatar", latitude: 25.2854, longitude: 51.5310, timeZoneID: "Asia/Qatar"),
        City(id: "kuwait", name: "Kuwait City", country: "Kuwait", latitude: 29.3759, longitude: 47.9774, timeZoneID: "Asia/Kuwait"),
        City(id: "manama", name: "Manama", country: "Bahrain", latitude: 26.2285, longitude: 50.5860, timeZoneID: "Asia/Bahrain"),
        City(id: "muscat", name: "Muscat", country: "Oman", latitude: 23.5880, longitude: 58.3829, timeZoneID: "Asia/Muscat"),
        City(id: "amman", name: "Amman", country: "Jordan", latitude: 31.9454, longitude: 35.9284, timeZoneID: "Asia/Amman"),
        City(id: "beirut", name: "Beirut", country: "Lebanon", latitude: 33.8938, longitude: 35.5018, timeZoneID: "Asia/Beirut"),
        City(id: "damascus", name: "Damascus", country: "Syria", latitude: 33.5138, longitude: 36.2765, timeZoneID: "Asia/Damascus"),
        City(id: "baghdad", name: "Baghdad", country: "Iraq", latitude: 33.3152, longitude: 44.3661, timeZoneID: "Asia/Baghdad"),
        City(id: "jerusalem", name: "Jerusalem", country: "Palestine/Israel", latitude: 31.7683, longitude: 35.2137, timeZoneID: "Asia/Jerusalem"),
        City(id: "sanaa", name: "Sana'a", country: "Yemen", latitude: 15.3694, longitude: 44.1910, timeZoneID: "Asia/Aden"),
        City(id: "tehran", name: "Tehran", country: "Iran", latitude: 35.6892, longitude: 51.3890, timeZoneID: "Asia/Tehran"),

        // North Africa
        City(id: "cairo", name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357, timeZoneID: "Africa/Cairo"),
        City(id: "alexandria", name: "Alexandria", country: "Egypt", latitude: 31.2001, longitude: 29.9187, timeZoneID: "Africa/Cairo"),
        City(id: "casablanca", name: "Casablanca", country: "Morocco", latitude: 33.5731, longitude: -7.5898, timeZoneID: "Africa/Casablanca"),
        City(id: "rabat", name: "Rabat", country: "Morocco", latitude: 34.0209, longitude: -6.8416, timeZoneID: "Africa/Casablanca"),
        City(id: "algiers", name: "Algiers", country: "Algeria", latitude: 36.7538, longitude: 3.0588, timeZoneID: "Africa/Algiers"),
        City(id: "tunis", name: "Tunis", country: "Tunisia", latitude: 36.8065, longitude: 10.1815, timeZoneID: "Africa/Tunis"),
        City(id: "tripoli", name: "Tripoli", country: "Libya", latitude: 32.8872, longitude: 13.1913, timeZoneID: "Africa/Tripoli"),
        City(id: "khartoum", name: "Khartoum", country: "Sudan", latitude: 15.5007, longitude: 32.5599, timeZoneID: "Africa/Khartoum"),

        // Sub-Saharan Africa
        City(id: "lagos", name: "Lagos", country: "Nigeria", latitude: 6.5244, longitude: 3.3792, timeZoneID: "Africa/Lagos"),
        City(id: "abuja", name: "Abuja", country: "Nigeria", latitude: 9.0765, longitude: 7.3986, timeZoneID: "Africa/Lagos"),
        City(id: "kano", name: "Kano", country: "Nigeria", latitude: 12.0022, longitude: 8.5920, timeZoneID: "Africa/Lagos"),
        City(id: "dakar", name: "Dakar", country: "Senegal", latitude: 14.7167, longitude: -17.4677, timeZoneID: "Africa/Dakar"),
        City(id: "nairobi", name: "Nairobi", country: "Kenya", latitude: -1.2921, longitude: 36.8219, timeZoneID: "Africa/Nairobi"),
        City(id: "mogadishu", name: "Mogadishu", country: "Somalia", latitude: 2.0469, longitude: 45.3182, timeZoneID: "Africa/Mogadishu"),
        City(id: "addisababa", name: "Addis Ababa", country: "Ethiopia", latitude: 9.0240, longitude: 38.7469, timeZoneID: "Africa/Addis_Ababa"),
        City(id: "daressalaam", name: "Dar es Salaam", country: "Tanzania", latitude: -6.7924, longitude: 39.2083, timeZoneID: "Africa/Dar_es_Salaam"),
        City(id: "johannesburg", name: "Johannesburg", country: "South Africa", latitude: -26.2041, longitude: 28.0473, timeZoneID: "Africa/Johannesburg"),
        City(id: "capetown", name: "Cape Town", country: "South Africa", latitude: -33.9249, longitude: 18.4241, timeZoneID: "Africa/Johannesburg"),

        // South Asia
        City(id: "karachi", name: "Karachi", country: "Pakistan", latitude: 24.8607, longitude: 67.0011, timeZoneID: "Asia/Karachi"),
        City(id: "lahore", name: "Lahore", country: "Pakistan", latitude: 31.5204, longitude: 74.3587, timeZoneID: "Asia/Karachi"),
        City(id: "islamabad", name: "Islamabad", country: "Pakistan", latitude: 33.6844, longitude: 73.0479, timeZoneID: "Asia/Karachi"),
        City(id: "delhi", name: "Delhi", country: "India", latitude: 28.7041, longitude: 77.1025, timeZoneID: "Asia/Kolkata"),
        City(id: "mumbai", name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777, timeZoneID: "Asia/Kolkata"),
        City(id: "hyderabad", name: "Hyderabad", country: "India", latitude: 17.3850, longitude: 78.4867, timeZoneID: "Asia/Kolkata"),
        City(id: "dhaka", name: "Dhaka", country: "Bangladesh", latitude: 23.8103, longitude: 90.4125, timeZoneID: "Asia/Dhaka"),
        City(id: "chittagong", name: "Chittagong", country: "Bangladesh", latitude: 22.3569, longitude: 91.7832, timeZoneID: "Asia/Dhaka"),
        City(id: "colombo", name: "Colombo", country: "Sri Lanka", latitude: 6.9271, longitude: 79.8612, timeZoneID: "Asia/Colombo"),
        City(id: "kabul", name: "Kabul", country: "Afghanistan", latitude: 34.5553, longitude: 69.2075, timeZoneID: "Asia/Kabul"),

        // Southeast & Central Asia
        City(id: "jakarta", name: "Jakarta", country: "Indonesia", latitude: -6.2088, longitude: 106.8456, timeZoneID: "Asia/Jakarta"),
        City(id: "surabaya", name: "Surabaya", country: "Indonesia", latitude: -7.2575, longitude: 112.7521, timeZoneID: "Asia/Jakarta"),
        City(id: "kualalumpur", name: "Kuala Lumpur", country: "Malaysia", latitude: 3.1390, longitude: 101.6869, timeZoneID: "Asia/Kuala_Lumpur"),
        City(id: "singapore", name: "Singapore", country: "Singapore", latitude: 1.3521, longitude: 103.8198, timeZoneID: "Asia/Singapore"),
        City(id: "bandarseri", name: "Bandar Seri Begawan", country: "Brunei", latitude: 4.9031, longitude: 114.9398, timeZoneID: "Asia/Brunei"),
        City(id: "manila", name: "Manila", country: "Philippines", latitude: 14.5995, longitude: 120.9842, timeZoneID: "Asia/Manila"),
        City(id: "tashkent", name: "Tashkent", country: "Uzbekistan", latitude: 41.2995, longitude: 69.2401, timeZoneID: "Asia/Tashkent"),
        City(id: "almaty", name: "Almaty", country: "Kazakhstan", latitude: 43.2220, longitude: 76.8512, timeZoneID: "Asia/Almaty"),
        City(id: "baku", name: "Baku", country: "Azerbaijan", latitude: 40.4093, longitude: 49.8671, timeZoneID: "Asia/Baku"),

        // Turkey & Europe
        City(id: "istanbul", name: "Istanbul", country: "Türkiye", latitude: 41.0082, longitude: 28.9784, timeZoneID: "Europe/Istanbul"),
        City(id: "ankara", name: "Ankara", country: "Türkiye", latitude: 39.9334, longitude: 32.8597, timeZoneID: "Europe/Istanbul"),
        City(id: "london", name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278, timeZoneID: "Europe/London"),
        City(id: "birmingham", name: "Birmingham", country: "United Kingdom", latitude: 52.4862, longitude: -1.8904, timeZoneID: "Europe/London"),
        City(id: "manchester", name: "Manchester", country: "United Kingdom", latitude: 53.4808, longitude: -2.2426, timeZoneID: "Europe/London"),
        City(id: "paris", name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, timeZoneID: "Europe/Paris"),
        City(id: "marseille", name: "Marseille", country: "France", latitude: 43.2965, longitude: 5.3698, timeZoneID: "Europe/Paris"),
        City(id: "berlin", name: "Berlin", country: "Germany", latitude: 52.5200, longitude: 13.4050, timeZoneID: "Europe/Berlin"),
        City(id: "cologne", name: "Cologne", country: "Germany", latitude: 50.9375, longitude: 6.9603, timeZoneID: "Europe/Berlin"),
        City(id: "amsterdam", name: "Amsterdam", country: "Netherlands", latitude: 52.3676, longitude: 4.9041, timeZoneID: "Europe/Amsterdam"),
        City(id: "brussels", name: "Brussels", country: "Belgium", latitude: 50.8503, longitude: 4.3517, timeZoneID: "Europe/Brussels"),
        City(id: "stockholm", name: "Stockholm", country: "Sweden", latitude: 59.3293, longitude: 18.0686, timeZoneID: "Europe/Stockholm"),
        City(id: "oslo", name: "Oslo", country: "Norway", latitude: 59.9139, longitude: 10.7522, timeZoneID: "Europe/Oslo"),
        City(id: "madrid", name: "Madrid", country: "Spain", latitude: 40.4168, longitude: -3.7038, timeZoneID: "Europe/Madrid"),
        City(id: "rome", name: "Rome", country: "Italy", latitude: 41.9028, longitude: 12.4964, timeZoneID: "Europe/Rome"),
        City(id: "vienna", name: "Vienna", country: "Austria", latitude: 48.2082, longitude: 16.3738, timeZoneID: "Europe/Vienna"),
        City(id: "sarajevo", name: "Sarajevo", country: "Bosnia", latitude: 43.8563, longitude: 18.4131, timeZoneID: "Europe/Sarajevo"),
        City(id: "tirana", name: "Tirana", country: "Albania", latitude: 41.3275, longitude: 19.8187, timeZoneID: "Europe/Tirane"),
        City(id: "moscow", name: "Moscow", country: "Russia", latitude: 55.7558, longitude: 37.6173, timeZoneID: "Europe/Moscow"),
        City(id: "kazan", name: "Kazan", country: "Russia", latitude: 55.8304, longitude: 49.0661, timeZoneID: "Europe/Moscow"),

        // Americas
        City(id: "newyork", name: "New York", country: "USA", latitude: 40.7128, longitude: -74.0060, timeZoneID: "America/New_York"),
        City(id: "newark", name: "Newark", country: "USA", latitude: 40.7357, longitude: -74.1724, timeZoneID: "America/New_York"),
        City(id: "chicago", name: "Chicago", country: "USA", latitude: 41.8781, longitude: -87.6298, timeZoneID: "America/Chicago"),
        City(id: "houston", name: "Houston", country: "USA", latitude: 29.7604, longitude: -95.3698, timeZoneID: "America/Chicago"),
        City(id: "dallas", name: "Dallas", country: "USA", latitude: 32.7767, longitude: -96.7970, timeZoneID: "America/Chicago"),
        City(id: "detroit", name: "Detroit", country: "USA", latitude: 42.3314, longitude: -83.0458, timeZoneID: "America/Detroit"),
        City(id: "losangeles", name: "Los Angeles", country: "USA", latitude: 34.0522, longitude: -118.2437, timeZoneID: "America/Los_Angeles"),
        City(id: "sanfrancisco", name: "San Francisco", country: "USA", latitude: 37.7749, longitude: -122.4194, timeZoneID: "America/Los_Angeles"),
        City(id: "seattle", name: "Seattle", country: "USA", latitude: 47.6062, longitude: -122.3321, timeZoneID: "America/Los_Angeles"),
        City(id: "minneapolis", name: "Minneapolis", country: "USA", latitude: 44.9778, longitude: -93.2650, timeZoneID: "America/Chicago"),
        City(id: "toronto", name: "Toronto", country: "Canada", latitude: 43.6532, longitude: -79.3832, timeZoneID: "America/Toronto"),
        City(id: "montreal", name: "Montréal", country: "Canada", latitude: 45.5019, longitude: -73.5674, timeZoneID: "America/Toronto"),
        City(id: "vancouver", name: "Vancouver", country: "Canada", latitude: 49.2827, longitude: -123.1207, timeZoneID: "America/Vancouver"),
        City(id: "mexicocity", name: "Mexico City", country: "Mexico", latitude: 19.4326, longitude: -99.1332, timeZoneID: "America/Mexico_City"),
        City(id: "saopaulo", name: "São Paulo", country: "Brazil", latitude: -23.5505, longitude: -46.6333, timeZoneID: "America/Sao_Paulo"),
        City(id: "buenosaires", name: "Buenos Aires", country: "Argentina", latitude: -34.6037, longitude: -58.3816, timeZoneID: "America/Argentina/Buenos_Aires"),

        // Oceania & East Asia
        City(id: "sydney", name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093, timeZoneID: "Australia/Sydney"),
        City(id: "melbourne", name: "Melbourne", country: "Australia", latitude: -37.8136, longitude: 144.9631, timeZoneID: "Australia/Melbourne"),
        City(id: "auckland", name: "Auckland", country: "New Zealand", latitude: -36.8509, longitude: 174.7645, timeZoneID: "Pacific/Auckland"),
        City(id: "tokyo", name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503, timeZoneID: "Asia/Tokyo"),
        City(id: "seoul", name: "Seoul", country: "South Korea", latitude: 37.5665, longitude: 126.9780, timeZoneID: "Asia/Seoul"),
        City(id: "beijing", name: "Beijing", country: "China", latitude: 39.9042, longitude: 116.4074, timeZoneID: "Asia/Shanghai"),
        City(id: "urumqi", name: "Ürümqi", country: "China", latitude: 43.8256, longitude: 87.6168, timeZoneID: "Asia/Shanghai"),
        City(id: "hongkong", name: "Hong Kong", country: "China", latitude: 22.3193, longitude: 114.1694, timeZoneID: "Asia/Hong_Kong"),
    ]
}
