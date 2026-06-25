import Foundation
import SwiftData

enum SpeciesClass: String, Codable, CaseIterable, Identifiable {
    case bird = "Bird"
    case mammal = "Mammal"
    case reptile = "Reptile"
    case amphibian = "Amphibian"
    case insect = "Insect"
    case arachnid = "Arachnid"
    case plant = "Plant"
    case tree = "Tree"
    case mushroom = "Mushroom/Fungi"
    case fish = "Fish"
    case other = "Other"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .bird:      return "bird.fill"
        case .mammal:    return "pawprint.fill"
        case .reptile:   return "lizard.fill"
        case .amphibian: return "drop.fill"
        case .insect:    return "ant.fill"
        case .arachnid:  return "star.fill"
        case .plant:     return "leaf.fill"
        case .tree:      return "tree.fill"
        case .mushroom:  return "moon.haze.fill"
        case .fish:      return "fish.fill"
        case .other:     return "questionmark.circle.fill"
        }
    }

    var emoji: String {
        switch self {
        case .bird: return "🐦"
        case .mammal: return "🐾"
        case .reptile: return "🦎"
        case .amphibian: return "🐸"
        case .insect: return "🐛"
        case .arachnid: return "🕷️"
        case .plant: return "🌿"
        case .tree: return "🌲"
        case .mushroom: return "🍄"
        case .fish: return "🐟"
        case .other: return "🔍"
        }
    }
}

enum ObservationQuality: String, Codable, CaseIterable, Identifiable {
    case brief = "Brief glimpse"
    case good = "Good view"
    case excellent = "Excellent"
    case photographed = "Photographed"

    var id: String { rawValue }
}

enum WeatherConditions: String, Codable, CaseIterable, Identifiable {
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    case overcast = "Overcast"
    case raining = "Raining"
    case fog = "Fog"
    case wind = "Windy"

    var id: String { rawValue }
    var sfSymbol: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .raining: return "cloud.rain.fill"
        case .fog: return "cloud.fog.fill"
        case .wind: return "wind"
        }
    }
}

@Model
final class Observation {
    var id: UUID = UUID()
    var date: Date = Date.now
    var speciesName: String = ""
    var speciesClass: SpeciesClass = SpeciesClass.bird
    var commonName: String = ""
    var count: Int = 1
    var locationName: String = ""
    var habitat: String = ""
    var quality: ObservationQuality = ObservationQuality.good
    var weather: WeatherConditions = WeatherConditions.sunny
    var behavior: String = ""
    var notes: String = ""
    var isLifer: Bool = false
    var tripName: String = ""

    init(
        date: Date = .now,
        speciesName: String = "",
        speciesClass: SpeciesClass = .bird,
        commonName: String = "",
        count: Int = 1,
        locationName: String = "",
        habitat: String = "",
        quality: ObservationQuality = .good,
        weather: WeatherConditions = .sunny,
        behavior: String = "",
        notes: String = "",
        isLifer: Bool = false,
        tripName: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.speciesName = speciesName
        self.speciesClass = speciesClass
        self.commonName = commonName
        self.count = count
        self.locationName = locationName
        self.habitat = habitat
        self.quality = quality
        self.weather = weather
        self.behavior = behavior
        self.notes = notes
        self.isLifer = isLifer
        self.tripName = tripName
    }

    var displayName: String {
        commonName.isEmpty ? speciesName : commonName
    }
}
