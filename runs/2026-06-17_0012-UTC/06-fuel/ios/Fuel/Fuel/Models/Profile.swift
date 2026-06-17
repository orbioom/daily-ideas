import Foundation
import SwiftData

/// The user's active plan. Effectively a singleton — the app uses the most
/// recently created profile. Canonical measurements stored in metric.
@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var sexRaw: String
    var birthDate: Date
    var heightCm: Double
    var startWeightKg: Double
    var currentWeightKg: Double
    var bodyFatPercent: Double?
    var activityRaw: String
    var goalRaw: String
    var goalRatePercent: Double
    var dietStyleRaw: String
    var customProteinPerKg: Double
    var customFatPerKg: Double
    var goalWeightKg: Double
    var createdAt: Date

    init(id: UUID = UUID(),
         sex: Sex,
         birthDate: Date,
         heightCm: Double,
         startWeightKg: Double,
         currentWeightKg: Double,
         bodyFatPercent: Double? = nil,
         activity: ActivityLevel,
         goal: Goal,
         goalRatePercent: Double,
         dietStyle: DietStyle,
         customProteinPerKg: Double = 2.0,
         customFatPerKg: Double = 0.8,
         goalWeightKg: Double,
         createdAt: Date = Date()) {
        self.id = id
        self.sexRaw = sex.rawValue
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.startWeightKg = startWeightKg
        self.currentWeightKg = currentWeightKg
        self.bodyFatPercent = bodyFatPercent
        self.activityRaw = activity.rawValue
        self.goalRaw = goal.rawValue
        self.goalRatePercent = goalRatePercent
        self.dietStyleRaw = dietStyle.rawValue
        self.customProteinPerKg = customProteinPerKg
        self.customFatPerKg = customFatPerKg
        self.goalWeightKg = goalWeightKg
        self.createdAt = createdAt
    }

    // MARK: - Typed accessors (raw-string backed enums)

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }
    var activity: ActivityLevel {
        get { ActivityLevel(rawValue: activityRaw) ?? .moderate }
        set { activityRaw = newValue.rawValue }
    }
    var goal: Goal {
        get { Goal(rawValue: goalRaw) ?? .maintain }
        set { goalRaw = newValue.rawValue }
    }
    var dietStyle: DietStyle {
        get { DietStyle(rawValue: dietStyleRaw) ?? .balanced }
        set { dietStyleRaw = newValue.rawValue }
    }

    /// Age in whole years from the birth date.
    var age: Int {
        let comps = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
        return max(0, comps.year ?? 30)
    }
}
