import Foundation

enum TrekSettings {
    static let onboardingCompleted = "trek_onboarding_v1"
    static let distanceUnit = "trek_distance_unit"
    static let elevationUnit = "trek_elevation_unit"
    static let hapticFeedback = "trek_haptic_feedback"
    static let defaultDifficulty = "trek_default_difficulty"
}

enum DistanceUnit: String, CaseIterable {
    case km = "Kilometers"
    case miles = "Miles"

    func convert(_ km: Double) -> Double {
        switch self {
        case .km: return km
        case .miles: return km * 0.621371
        }
    }

    func label(_ km: Double) -> String {
        switch self {
        case .km: return String(format: "%.1f km", km)
        case .miles: return String(format: "%.1f mi", km * 0.621371)
        }
    }

    var shortLabel: String {
        switch self {
        case .km: return "km"
        case .miles: return "mi"
        }
    }
}

enum ElevationUnit: String, CaseIterable {
    case meters = "Meters"
    case feet = "Feet"

    func convert(_ m: Double) -> Double {
        switch self {
        case .meters: return m
        case .feet: return m * 3.28084
        }
    }

    func label(_ m: Double) -> String {
        switch self {
        case .meters: return String(format: "%.0f m", m)
        case .feet: return String(format: "%.0f ft", m * 3.28084)
        }
    }

    var shortLabel: String {
        switch self {
        case .meters: return "m"
        case .feet: return "ft"
        }
    }
}

extension Double {
    func distanceString(unit: DistanceUnit) -> String { unit.label(self) }
    func elevationString(unit: ElevationUnit) -> String { unit.label(self) }
}
