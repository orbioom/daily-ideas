import Foundation

/// Resolves a plan id to its runtime `TrainingPlan`. Knows the built-in plans
/// always; custom plans are registered as they're loaded from SwiftData so the
/// player can restore an in-progress custom-plan run after relaunch.
final class PlanResolver {
    static let shared = PlanResolver()

    private var customPlans: [String: TrainingPlan] = [:]

    private init() {}

    /// Register / refresh the custom plans currently in the store.
    func registerCustom(_ plans: [TrainingPlan]) {
        var map: [String: TrainingPlan] = [:]
        for p in plans { map[p.id] = p }
        customPlans = map
    }

    /// Look up any plan (built-in first, then registered custom).
    func plan(id: String) -> TrainingPlan? {
        if let built = BuiltInPlans.plan(id: id) { return built }
        return customPlans[id]
    }
}
