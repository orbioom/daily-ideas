import Foundation

/// Pure-Swift calorie & macro calculation engine. No UI, no persistence —
/// every value here is deterministic and unit-tested by inspection.
///
/// Energy constants:
///   - 7700 kcal per kg of body mass (≈ 3500 kcal/lb).
///   - 4 kcal/g protein, 4 kcal/g carbohydrate, 9 kcal/g fat.
enum MacroEngine {

    static let kcalPerKg: Double = 7700
    static let kcalPerGramProtein: Double = 4
    static let kcalPerGramCarb: Double = 4
    static let kcalPerGramFat: Double = 9

    // MARK: - Guardrail thresholds

    /// Recommended maximum cut rate (% bodyweight / week) before we warn.
    static let safeCutRate: Double = 1.0
    /// Recommended maximum lean-bulk rate (% bodyweight / week) before we warn.
    static let safeBulkRate: Double = 0.5

    // MARK: - Lean body mass & BMR

    /// Lean body mass in kg from weight and body-fat fraction (0…1).
    static func leanBodyMassKg(weightKg: Double, bodyFatPercent: Double?) -> Double? {
        guard let bf = bodyFatPercent, bf > 0, bf < 100, weightKg > 0 else { return nil }
        return weightKg * (1.0 - bf / 100.0)
    }

    /// Mifflin-St Jeor basal metabolic rate (kcal/day).
    /// male:   10·kg + 6.25·cm − 5·age + 5
    /// female: 10·kg + 6.25·cm − 5·age − 161
    static func mifflinBMR(sex: Sex, weightKg: Double, heightCm: Double, age: Int) -> Double {
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age)
        return sex == .male ? base + 5.0 : base - 161.0
    }

    /// Katch-McArdle basal metabolic rate (kcal/day): 370 + 21.6·LBM(kg).
    static func katchBMR(leanBodyMassKg lbm: Double) -> Double {
        370.0 + 21.6 * lbm
    }

    /// Resolve a BMR using the requested formula, falling back to Mifflin when
    /// Katch is requested but body-fat is unavailable.
    static func bmr(formula: BMRFormula,
                    sex: Sex,
                    weightKg: Double,
                    heightCm: Double,
                    age: Int,
                    bodyFatPercent: Double?) -> Double {
        if formula == .katch, let lbm = leanBodyMassKg(weightKg: weightKg, bodyFatPercent: bodyFatPercent) {
            return max(0, katchBMR(leanBodyMassKg: lbm))
        }
        return max(0, mifflinBMR(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age))
    }

    // MARK: - Maintenance TDEE

    /// Maintenance total daily energy expenditure = BMR × activity multiplier.
    static func maintenanceTDEE(bmr: Double, activity: ActivityLevel) -> Double {
        max(0, bmr * activity.multiplier)
    }

    // MARK: - Goal calorie delta

    /// Daily kcal delta implied by a goal rate expressed as % bodyweight / week.
    /// deltaPerDay = (rate% × weight_kg × 7700) / 7. Sign follows the goal.
    static func dailyKcalDelta(goal: Goal, ratePercent: Double, weightKg: Double) -> Double {
        guard weightKg > 0 else { return 0 }
        let magnitude = (abs(ratePercent) / 100.0) * weightKg * kcalPerKg / 7.0
        return goal.direction * magnitude
    }

    /// A safe calorie floor: the larger of a sex-based minimum and BMR×1.0.
    static func calorieFloor(sex: Sex, bmr: Double) -> Double {
        let sexFloor = sex == .female ? 1200.0 : 1500.0
        return max(sexFloor, bmr)
    }

    /// Round calories to the nearest `step` (e.g. 5 or 10). step 1 → no rounding.
    static func roundCalories(_ value: Double, to step: Int) -> Double {
        guard step > 1 else { return value.rounded() }
        let s = Double(step)
        return (value / s).rounded() * s
    }

    // MARK: - Full target computation

    /// Compute a full calorie + macro target plan from a snapshot of inputs.
    static func computeTarget(sex: Sex,
                              weightKg: Double,
                              heightCm: Double,
                              age: Int,
                              bodyFatPercent: Double?,
                              activity: ActivityLevel,
                              goal: Goal,
                              ratePercent: Double,
                              dietStyle: DietStyle,
                              formula: BMRFormula,
                              customProteinPerKg: Double,
                              customFatPerKg: Double,
                              roundTo: Int) -> TargetResult {

        let bmrValue = bmr(formula: formula, sex: sex, weightKg: weightKg,
                           heightCm: heightCm, age: age, bodyFatPercent: bodyFatPercent)
        let tdee = maintenanceTDEE(bmr: bmrValue, activity: activity)
        let delta = goal == .maintain ? 0 : dailyKcalDelta(goal: goal, ratePercent: ratePercent, weightKg: weightKg)

        let rawTarget = tdee + delta
        let floor = calorieFloor(sex: sex, bmr: bmrValue)

        var warnings: [String] = []
        // Safe-rate guardrails.
        if goal == .cut && ratePercent > safeCutRate {
            warnings.append("A cut faster than \(Self.format(safeCutRate))%/week risks muscle loss & fatigue.")
        }
        if goal == .bulk && ratePercent > safeBulkRate {
            warnings.append("A bulk faster than \(Self.format(safeBulkRate))%/week tends to add more fat than muscle.")
        }

        var clampedTarget = rawTarget
        var clampedToFloor = false
        if clampedTarget < floor {
            clampedTarget = floor
            clampedToFloor = true
            warnings.append("Target raised to a safe floor of \(Int(floor.rounded())) kcal — your chosen rate was too aggressive for your size.")
        }

        let calories = roundCalories(clampedTarget, to: roundTo)
        let macros = MacroSplit.compute(dietStyle: dietStyle,
                                        calories: calories,
                                        weightKg: weightKg,
                                        bodyFatPercent: bodyFatPercent,
                                        customProteinPerKg: customProteinPerKg,
                                        customFatPerKg: customFatPerKg)

        return TargetResult(bmr: bmrValue,
                            maintenanceTDEE: tdee,
                            dailyDelta: delta,
                            rawTarget: rawTarget,
                            calorieTarget: calories,
                            floor: floor,
                            clampedToFloor: clampedToFloor,
                            macros: macros,
                            warnings: warnings)
    }

    /// Format a number trimming a trailing .0.
    static func format(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

/// Result of a full target computation.
struct TargetResult: Equatable {
    let bmr: Double
    let maintenanceTDEE: Double
    let dailyDelta: Double
    let rawTarget: Double
    let calorieTarget: Double
    let floor: Double
    let clampedToFloor: Bool
    let macros: MacroTargets
    let warnings: [String]
}

/// Resolved grams + kcal for each macro.
struct MacroTargets: Equatable {
    var proteinG: Double
    var carbG: Double
    var fatG: Double

    var proteinKcal: Double { proteinG * MacroEngine.kcalPerGramProtein }
    var carbKcal: Double { carbG * MacroEngine.kcalPerGramCarb }
    var fatKcal: Double { fatG * MacroEngine.kcalPerGramFat }

    var totalKcal: Double { proteinKcal + carbKcal + fatKcal }

    /// Percentage of total kcal from each macro (guards against zero total).
    func percent(of kcal: Double) -> Double {
        guard totalKcal > 0 else { return 0 }
        return kcal / totalKcal * 100.0
    }

    var proteinPercent: Double { percent(of: proteinKcal) }
    var carbPercent: Double { percent(of: carbKcal) }
    var fatPercent: Double { percent(of: fatKcal) }
}

/// Builds macro grams from a diet style preset.
enum MacroSplit {

    /// Minimum dietary fat in g/kg bodyweight — never go below this.
    static let minFatPerKg: Double = 0.6

    /// Default protein anchor in g/kg for each preset.
    static func proteinPerKg(for style: DietStyle, custom: Double) -> Double {
        switch style {
        case .balanced:    return 1.8
        case .highProtein: return 2.2
        case .lowCarb:     return 2.0
        case .keto:        return 1.8
        case .custom:      return max(0.5, custom)
        }
    }

    /// Compute grams of each macro for a given calorie budget.
    ///
    /// Protein is anchored as g/kg. For keto/low-carb we anchor fat (or carbs)
    /// and distribute the remainder; for balanced/high-protein we use a target
    /// carb/fat kcal split. All branches guard against negatives.
    static func compute(dietStyle: DietStyle,
                        calories: Double,
                        weightKg: Double,
                        bodyFatPercent: Double?,
                        customProteinPerKg: Double,
                        customFatPerKg: Double) -> MacroTargets {

        let safeCalories = max(0, calories)
        let safeWeight = max(1, weightKg)

        // Protein anchor (g) — clamp so protein kcal never exceeds the budget.
        let proteinGRaw = proteinPerKg(for: dietStyle, custom: customProteinPerKg) * safeWeight
        let maxProteinG = safeCalories / MacroEngine.kcalPerGramProtein
        let proteinG = max(0, min(proteinGRaw, maxProteinG))
        let proteinKcal = proteinG * MacroEngine.kcalPerGramProtein
        let remainingKcal = max(0, safeCalories - proteinKcal)

        // Minimum fat floor in grams.
        let minFatG = minFatPerKg * safeWeight

        var fatG: Double
        var carbG: Double

        switch dietStyle {
        case .keto:
            // ~5% of calories from carbs, the rest from fat.
            let carbKcal = min(remainingKcal, safeCalories * 0.05)
            carbG = carbKcal / MacroEngine.kcalPerGramCarb
            let fatKcal = max(0, remainingKcal - carbKcal)
            fatG = fatKcal / MacroEngine.kcalPerGramFat

        case .lowCarb:
            // Anchor a generous fat intake, give the rest to carbs.
            let targetFatG = max(minFatG, 1.0 * safeWeight)
            let targetFatKcal = min(remainingKcal, targetFatG * MacroEngine.kcalPerGramFat)
            fatG = targetFatKcal / MacroEngine.kcalPerGramFat
            let carbKcal = max(0, remainingKcal - targetFatKcal)
            carbG = carbKcal / MacroEngine.kcalPerGramCarb

        case .custom:
            // Anchor fat at the user's g/kg, remainder to carbs.
            let targetFatG = max(minFatG, max(0.4, customFatPerKg) * safeWeight)
            let targetFatKcal = min(remainingKcal, targetFatG * MacroEngine.kcalPerGramFat)
            fatG = targetFatKcal / MacroEngine.kcalPerGramFat
            let carbKcal = max(0, remainingKcal - targetFatKcal)
            carbG = carbKcal / MacroEngine.kcalPerGramCarb

        case .balanced, .highProtein:
            // Split the remaining calories between carbs and fat.
            // Balanced ≈ 60/40 carb/fat of remainder; high-protein ≈ 55/45.
            let carbShare = dietStyle == .balanced ? 0.60 : 0.55
            var carbKcal = remainingKcal * carbShare
            var fatKcal = remainingKcal * (1 - carbShare)
            // Enforce the fat minimum, borrowing from carbs if needed.
            let minFatKcal = minFatG * MacroEngine.kcalPerGramFat
            if fatKcal < minFatKcal {
                let deficit = min(minFatKcal - fatKcal, carbKcal)
                fatKcal += deficit
                carbKcal -= deficit
            }
            carbG = max(0, carbKcal) / MacroEngine.kcalPerGramCarb
            fatG = max(0, fatKcal) / MacroEngine.kcalPerGramFat
        }

        return MacroTargets(proteinG: proteinG.rounded(),
                            carbG: carbG.rounded(),
                            fatG: fatG.rounded())
    }
}
