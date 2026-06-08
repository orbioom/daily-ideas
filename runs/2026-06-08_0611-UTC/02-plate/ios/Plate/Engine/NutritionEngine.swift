import Foundation

struct MacroTargets {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct DayTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

enum NutritionEngine {

    // MARK: - BMR (Mifflin-St Jeor)
    static func bmr(sex: Sex, age: Int, heightCm: Double, weightKg: Double) -> Double {
        let base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        switch sex {
        case .male:   return base + 5.0
        case .female: return base - 161.0
        }
    }

    // MARK: - TDEE
    static func tdee(sex: Sex, age: Int, heightCm: Double, weightKg: Double, activity: Activity) -> Double {
        bmr(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg) * activity.factor
    }

    // MARK: - Target calories
    static func targetCalories(goal: UserGoal) -> Double {
        let raw = tdee(
            sex: goal.sex,
            age: goal.age,
            heightCm: goal.heightCm,
            weightKg: goal.weightKg,
            activity: goal.activity
        ) + goal.objective.delta
        return max(raw, 1200.0)
    }

    // MARK: - Macro targets
    static func macroTargets(calories: Double, weightKg: Double, objective: Objective) -> MacroTargets {
        let proteinG = min(max(weightKg * 1.8, 50.0), 250.0)
        let fatG = (calories * 0.27) / 9.0
        let proteinKcal = proteinG * 4.0
        let fatKcal = fatG * 9.0
        let remainingKcal = calories - proteinKcal - fatKcal
        let carbG = max(remainingKcal / 4.0, 0.0)
        return MacroTargets(calories: calories, protein: proteinG, carbs: carbG, fat: fatG)
    }

    // MARK: - Day totals
    static func dayTotals(_ entries: [DiaryEntry]) -> DayTotals {
        let cal = entries.reduce(0.0) { $0 + $1.calories }
        let pro = entries.reduce(0.0) { $0 + $1.protein }
        let carb = entries.reduce(0.0) { $0 + $1.carbs }
        let fat = entries.reduce(0.0) { $0 + $1.fat }
        return DayTotals(calories: cal, protein: pro, carbs: carb, fat: fat)
    }

    // MARK: - Remaining
    static func remaining(target: Double, consumed: Double) -> Double {
        target - consumed
    }

    // MARK: - Recompute goal targets
    static func recompute(into goal: UserGoal) {
        guard !goal.useManualTargets else { return }
        let cal = targetCalories(goal: goal)
        let macros = macroTargets(calories: cal, weightKg: goal.weightKg, objective: goal.objective)
        goal.calorieTarget = macros.calories
        goal.proteinTarget = macros.protein
        goal.carbTarget = macros.carbs
        goal.fatTarget = macros.fat
    }
}
