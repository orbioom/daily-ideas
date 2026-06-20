import Foundation
import SwiftData

@Model
final class CanopySettings {
    var weeklyGoalKg: Double
    var unitSystem: String
    var hasCompletedOnboarding: Bool
    var hasPro: Bool

    init(
        weeklyGoalKg: Double = 92.0,
        unitSystem: String = "metric",
        hasCompletedOnboarding: Bool = false,
        hasPro: Bool = false
    ) {
        self.weeklyGoalKg = weeklyGoalKg
        self.unitSystem = unitSystem
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPro = hasPro
    }

    var isMetric: Bool {
        unitSystem == "metric"
    }

    func formatted(kg: Double) -> String {
        if isMetric {
            return String(format: "%.1f kg", kg)
        } else {
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
    }
}
