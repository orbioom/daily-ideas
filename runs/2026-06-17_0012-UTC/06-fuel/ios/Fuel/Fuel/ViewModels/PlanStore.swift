import Foundation
import SwiftData
import Observation

/// A derived snapshot of "what should I eat today", computed from the active
/// profile + current preferences. Pure, recomputed on demand.
struct CurrentPlan: Equatable {
    let profile: ProfileSnapshot
    let target: TargetResult

    /// Convenience: macro targets.
    var macros: MacroTargets { target.macros }
}

/// A value-type copy of the active profile so derived computations don't keep a
/// live reference to the SwiftData model (avoids surprise mutation).
struct ProfileSnapshot: Equatable {
    let sex: Sex
    let age: Int
    let heightCm: Double
    let startWeightKg: Double
    let currentWeightKg: Double
    let bodyFatPercent: Double?
    let activity: ActivityLevel
    let goal: Goal
    let goalRatePercent: Double
    let dietStyle: DietStyle
    let customProteinPerKg: Double
    let customFatPerKg: Double
    let goalWeightKg: Double
    let createdAt: Date

    init(profile: Profile) {
        sex = profile.sex
        age = profile.age
        heightCm = profile.heightCm
        startWeightKg = profile.startWeightKg
        currentWeightKg = profile.currentWeightKg
        bodyFatPercent = profile.bodyFatPercent
        activity = profile.activity
        goal = profile.goal
        goalRatePercent = profile.goalRatePercent
        dietStyle = profile.dietStyle
        customProteinPerKg = profile.customProteinPerKg
        customFatPerKg = profile.customFatPerKg
        goalWeightKg = profile.goalWeightKg
        createdAt = profile.createdAt
    }
}

/// Pure helpers that turn a profile + settings into a computed plan. Static so
/// any view can call without owning state.
enum PlanCalculator {

    static func target(for profile: Profile, settings: AppSettings) -> TargetResult {
        MacroEngine.computeTarget(
            sex: profile.sex,
            weightKg: profile.currentWeightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            bodyFatPercent: profile.bodyFatPercent,
            activity: profile.activity,
            goal: profile.goal,
            ratePercent: profile.goalRatePercent,
            dietStyle: profile.dietStyle,
            formula: settings.bmrFormula,
            customProteinPerKg: profile.customProteinPerKg,
            customFatPerKg: profile.customFatPerKg,
            roundTo: settings.roundTo
        )
    }

    /// The most recent applied calorie target (from snapshots), falling back to
    /// the freshly computed plan target when no snapshots exist.
    static func activeTarget(snapshots: [TargetSnapshot], computed: TargetResult) -> Double {
        if let latest = snapshots.sorted(by: { $0.date > $1.date }).first {
            return latest.calorieTarget
        }
        return computed.calorieTarget
    }
}
