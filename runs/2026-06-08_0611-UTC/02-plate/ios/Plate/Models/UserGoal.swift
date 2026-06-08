import SwiftData
import Foundation

enum Sex: String, Codable, CaseIterable {
    case male
    case female

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
    }
}

enum Activity: String, Codable, CaseIterable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    var displayName: String {
        switch self {
        case .sedentary:  return "Sedentary"
        case .light:      return "Lightly Active"
        case .moderate:   return "Moderately Active"
        case .active:     return "Active"
        case .veryActive: return "Very Active"
        }
    }

    var factor: Double {
        switch self {
        case .sedentary:  return 1.2
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum Objective: String, Codable, CaseIterable {
    case lose
    case maintain
    case gain

    var displayName: String {
        switch self {
        case .lose:     return "Lose Weight"
        case .maintain: return "Maintain Weight"
        case .gain:     return "Gain Weight"
        }
    }

    /// Kilocalorie delta applied on top of TDEE
    var delta: Double {
        switch self {
        case .lose:     return -500.0
        case .maintain: return 0.0
        case .gain:     return 300.0
        }
    }
}

@Model
final class UserGoal {
    var id: UUID
    var calorieTarget: Double
    var proteinTarget: Double
    var carbTarget: Double
    var fatTarget: Double
    var sex: Sex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var activity: Activity
    var objective: Objective
    var useManualTargets: Bool

    init(
        id: UUID = UUID(),
        calorieTarget: Double = 2000,
        proteinTarget: Double = 150,
        carbTarget: Double = 225,
        fatTarget: Double = 60,
        sex: Sex = .male,
        age: Int = 30,
        heightCm: Double = 175,
        weightKg: Double = 75,
        activity: Activity = .moderate,
        objective: Objective = .maintain,
        useManualTargets: Bool = false
    ) {
        self.id = id
        self.calorieTarget = calorieTarget
        self.proteinTarget = proteinTarget
        self.carbTarget = carbTarget
        self.fatTarget = fatTarget
        self.sex = sex
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activity = activity
        self.objective = objective
        self.useManualTargets = useManualTargets
    }
}
