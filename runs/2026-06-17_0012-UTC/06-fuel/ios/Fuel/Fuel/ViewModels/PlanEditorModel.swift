import Foundation
import Observation

/// Editable, validated working copy of a profile used by the Plan editor. Holds
/// values in canonical metric; the view converts to/from display units. Computes
/// a live target preview as the user edits.
@Observable
final class PlanEditorModel {

    var sex: Sex
    var age: Int
    var heightCm: Double
    var currentWeightKg: Double
    var bodyFatText: String          // optional; empty = none
    var activity: ActivityLevel
    var goal: Goal
    var goalRatePercent: Double
    var dietStyle: DietStyle
    var customProteinPerKg: Double
    var customFatPerKg: Double
    var goalWeightKg: Double

    init(profile: Profile?, defaultProteinPerKg: Double) {
        if let p = profile {
            sex = p.sex
            age = p.age
            heightCm = p.heightCm
            currentWeightKg = p.currentWeightKg
            bodyFatText = p.bodyFatPercent.map { String(format: "%.0f", $0) } ?? ""
            activity = p.activity
            goal = p.goal
            goalRatePercent = p.goalRatePercent
            dietStyle = p.dietStyle
            customProteinPerKg = p.customProteinPerKg
            customFatPerKg = p.customFatPerKg
            goalWeightKg = p.goalWeightKg
        } else {
            sex = .male
            age = 30
            heightCm = 175
            currentWeightKg = 80
            bodyFatText = ""
            activity = .moderate
            goal = .cut
            goalRatePercent = 0.6
            dietStyle = .balanced
            customProteinPerKg = max(0.5, defaultProteinPerKg)
            customFatPerKg = 0.8
            goalWeightKg = 75
        }
    }

    var bodyFatPercent: Double? {
        let trimmed = bodyFatText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let v = Double(trimmed), v > 0, v < 70 else { return nil }
        return v
    }

    // MARK: - Validation

    var isValid: Bool { validationErrors.isEmpty }

    var validationErrors: [String] {
        var errs: [String] = []
        if currentWeightKg <= 0 { errs.append("Enter a weight above zero.") }
        if heightCm <= 0 { errs.append("Enter a height above zero.") }
        if age <= 0 || age > 120 { errs.append("Enter a realistic age.") }
        if goalWeightKg <= 0 { errs.append("Enter a goal weight above zero.") }
        if goal == .cut && goalWeightKg >= currentWeightKg {
            errs.append("For a cut, goal weight should be below your current weight.")
        }
        if goal == .bulk && goalWeightKg <= currentWeightKg {
            errs.append("For a bulk, goal weight should be above your current weight.")
        }
        return errs
    }

    /// Compute the live target preview using the supplied formula & rounding.
    func preview(formula: BMRFormula, roundTo: Int) -> TargetResult {
        MacroEngine.computeTarget(
            sex: sex,
            weightKg: max(1, currentWeightKg),
            heightCm: max(1, heightCm),
            age: max(1, age),
            bodyFatPercent: bodyFatPercent,
            activity: activity,
            goal: goal,
            ratePercent: goalRatePercent,
            dietStyle: dietStyle,
            formula: formula,
            customProteinPerKg: customProteinPerKg,
            customFatPerKg: customFatPerKg,
            roundTo: roundTo
        )
    }

    /// The maximum sensible rate slider value for the current goal.
    var maxRate: Double { goal == .bulk ? 1.0 : 1.5 }
}
