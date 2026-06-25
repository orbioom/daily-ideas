import Foundation
import SwiftData

enum HabitatType: String, Codable, CaseIterable, Identifiable {
    case forest = "Forest"
    case wetland = "Wetland"
    case grassland = "Grassland"
    case coastal = "Coastal"
    case urban = "Urban/Park"
    case mountain = "Mountain"
    case desert = "Desert"
    case riparian = "Riparian"
    case agricultural = "Agricultural"

    var id: String { rawValue }
    var sfSymbol: String {
        switch self {
        case .forest: return "tree.fill"
        case .wetland: return "water.waves"
        case .grassland: return "leaf.fill"
        case .coastal: return "beach.umbrella.fill"
        case .urban: return "building.2.fill"
        case .mountain: return "mountain.2.fill"
        case .desert: return "sun.max.fill"
        case .riparian: return "drop.fill"
        case .agricultural: return "allergens"
        }
    }
}

@Model
final class FieldTrip {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date.now
    var locationName: String = ""
    var habitatType: HabitatType = HabitatType.forest
    var durationMinutes: Int = 120
    var distanceKm: Double = 0.0
    var weather: WeatherConditions = WeatherConditions.sunny
    var notes: String = ""
    var isCompleted: Bool = false

    init(
        name: String = "",
        date: Date = .now,
        locationName: String = "",
        habitatType: HabitatType = .forest,
        durationMinutes: Int = 120,
        distanceKm: Double = 0.0,
        weather: WeatherConditions = .sunny,
        notes: String = "",
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.locationName = locationName
        self.habitatType = habitatType
        self.durationMinutes = durationMinutes
        self.distanceKm = distanceKm
        self.weather = weather
        self.notes = notes
        self.isCompleted = isCompleted
    }

    var durationFormatted: String {
        let h = durationMinutes / 60; let m = durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

@Model
final class FieldSettings {
    var id: UUID = UUID()
    var showOnboarding: Bool = true
    var hapticsEnabled: Bool = true
    var defaultHabitat: HabitatType = HabitatType.forest
    var useMetricDistance: Bool = true
    var liferAlerts: Bool = true
    var reminderEnabled: Bool = false
    var reminderHour: Int = 7

    init() { self.id = UUID() }
}
