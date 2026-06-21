import Foundation
import SwiftData

@Model
final class ObservingSession {
    var date: Date
    var locationName: String
    var notes: String
    var skyQuality: Int // 1-5 (Bortle scale approximation)
    var objectsNoted: [String]

    init(date: Date = .now, locationName: String = "", notes: String = "", skyQuality: Int = 3, objectsNoted: [String] = []) {
        self.date = date
        self.locationName = locationName
        self.notes = notes
        self.skyQuality = skyQuality
        self.objectsNoted = objectsNoted
    }
}

@Model
final class NovaSettings {
    var hasCompletedOnboarding: Bool
    var selectedCityIndex: Int
    var limitingMagnitude: Double
    var showConstellationLines: Bool
    var showConstellationNames: Bool
    var showPlanets: Bool
    var showMoon: Bool
    var northUp: Bool
    var hapticsEnabled: Bool
    var isPro: Bool

    init() {
        self.hasCompletedOnboarding = false
        self.selectedCityIndex = 0
        self.limitingMagnitude = 4.5
        self.showConstellationLines = true
        self.showConstellationNames = true
        self.showPlanets = true
        self.showMoon = true
        self.northUp = true
        self.hapticsEnabled = true
        self.isPro = false
    }
}

struct CelestialCity: Identifiable {
    let id: Int
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String
}

enum PlanetName: String, CaseIterable {
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"

    var symbol: String {
        switch self {
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        }
    }
}

struct Star: Identifiable {
    let id: Int
    let name: String
    let constellation: String
    let raDeg: Double   // right ascension in degrees
    let decDeg: Double  // declination in degrees
    let magnitude: Double
    let bv: Double      // B-V color index
    let spectralType: String
    let description: String
}

struct SkyObject: Identifiable {
    let id = UUID()
    let name: String
    let kind: SkyObjectKind
    let raDeg: Double
    let decDeg: Double
    let magnitude: Double
    var altDeg: Double = 0
    var azDeg: Double = 0
    var isAboveHorizon: Bool { altDeg > 0 }
    var bv: Double = 0
}

enum SkyObjectKind {
    case star(id: Int)
    case planet(name: PlanetName)
    case moon
    case sun
}

struct ConstellationData {
    let name: String
    let abbreviation: String
    let lines: [(Int, Int)] // pairs of star catalog indices
}
