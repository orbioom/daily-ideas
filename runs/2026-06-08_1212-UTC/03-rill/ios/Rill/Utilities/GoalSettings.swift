import Foundation

/// Central place to read the user's goal preferences from UserDefaults so every
/// screen agrees on the target. Backed by the same keys the Settings screen
/// writes via @AppStorage.
enum GoalSettings {
    static let defaults = UserDefaults.standard

    static func registerDefaults() {
        defaults.register(defaults: [
            "useSmartGoal": true,
            "manualGoalML": 2500.0,
            "weightKg": 70.0,
            "bodyProfile": BodyProfile.other.rawValue,
            "activityLevel": ActivityLevel.moderate.rawValue,
            "climate": Climate.temperate.rawValue,
            "volumeUnit": VolumeUnit.ml.rawValue,
        ])
    }

    static var unit: VolumeUnit {
        VolumeUnit(rawValue: defaults.string(forKey: "volumeUnit") ?? "ml") ?? .ml
    }

    static var goalML: Double {
        if defaults.bool(forKey: "useSmartGoal") {
            let engine = HydrationEngine()
            return engine.recommendedGoalML(
                weightKg: defaults.double(forKey: "weightKg"),
                profile: BodyProfile(rawValue: defaults.string(forKey: "bodyProfile") ?? "other") ?? .other,
                activity: ActivityLevel(rawValue: defaults.string(forKey: "activityLevel") ?? "moderate") ?? .moderate,
                climate: Climate(rawValue: defaults.string(forKey: "climate") ?? "temperate") ?? .temperate
            )
        } else {
            let manual = defaults.double(forKey: "manualGoalML")
            return manual > 0 ? manual : 2500
        }
    }
}
