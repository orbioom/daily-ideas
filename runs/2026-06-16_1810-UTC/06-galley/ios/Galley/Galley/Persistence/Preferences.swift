import Foundation

/// Keys + defaults for @AppStorage-backed preferences. Centralized so the
/// Settings screen and feature screens agree on names and default values.
enum PrefKey {
    static let hasOnboarded = "hasOnboarded"
    static let isPro = "isPro"
    static let hapticsEnabled = "hapticsEnabled"
    static let useFractions = "useFractions"
    static let measurementSystem = "measurementSystem"
    static let temperatureUnit = "temperatureUnit"
    static let lastIngredientID = "lastIngredientID"
}

/// Default measurement system preference.
enum MeasurementSystem: String, CaseIterable, Identifiable {
    case us = "US Customary"
    case metric = "Metric"
    var id: String { rawValue }

    /// Preferred default volume unit for this system.
    var defaultVolumeUnit: MeasureUnit { self == .us ? .cup : .milliliter }
    /// Preferred default weight unit for this system.
    var defaultWeightUnit: MeasureUnit { self == .us ? .ounce : .gram }
}

/// Default temperature unit preference.
enum TemperatureUnit: String, CaseIterable, Identifiable {
    case fahrenheit = "Fahrenheit"
    case celsius = "Celsius"
    var id: String { rawValue }
    var symbol: String { self == .fahrenheit ? "°F" : "°C" }
}

/// Limits applied to the free tier (lifted by Galley Pro).
enum FreeTier {
    static let maxSavedRecipes = 3
    static let maxTimers = 2
}
