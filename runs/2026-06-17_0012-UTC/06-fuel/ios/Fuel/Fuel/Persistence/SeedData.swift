import Foundation
import SwiftData

/// Seeds a realistic demo profile plus ~10 weeks of noisy check-ins on first
/// launch so the charts and adaptive logic have real data to work with.
/// Idempotent: it checks for an existing profile before inserting anything.
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        // Only seed when there is no profile yet.
        let descriptor = FetchDescriptor<Profile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date()

        // A 34-year-old male, moderately active, on a gentle 0.6%/week cut.
        guard let birth = cal.date(byAdding: .year, value: -34, to: now) else { return }

        let startWeight = 84.0
        let goalWeight = 76.0
        let profile = Profile(
            sex: .male,
            birthDate: birth,
            heightCm: 180,
            startWeightKg: startWeight,
            currentWeightKg: 80.6,
            bodyFatPercent: 20.0,
            activity: .moderate,
            goal: .cut,
            goalRatePercent: 0.6,
            dietStyle: .highProtein,
            customProteinPerKg: 2.0,
            customFatPerKg: 0.8,
            goalWeightKg: goalWeight,
            createdAt: cal.date(byAdding: .day, value: -70, to: now) ?? now
        )
        context.insert(profile)

        // 11 weekly weigh-ins trending down ~0.4 kg/week with realistic noise.
        // Some weeks include a logged average intake to exercise the energy-balance path.
        let weeklyWeights: [(Double, Double?)] = [
            (84.0, 2150),
            (83.4, 2150),
            (83.6, nil),     // water-weight bump — noise
            (82.9, 2100),
            (82.4, 2100),
            (82.6, nil),
            (81.8, 2080),
            (81.3, 2080),
            (81.5, nil),     // plateau wobble
            (80.9, 2050),
            (80.6, 2050)
        ]

        for (i, entry) in weeklyWeights.enumerated() {
            let weeksAgo = (weeklyWeights.count - 1 - i)
            guard let date = cal.date(byAdding: .day, value: -weeksAgo * 7, to: now) else { continue }
            let note: String
            switch i {
            case 0: note = "Starting the cut."
            case 2: note = "Up a bit — high-sodium weekend."
            case 8: note = "Feeling a plateau."
            default: note = ""
            }
            let checkIn = CheckIn(date: date,
                                  weightKg: entry.0,
                                  avgDailyIntakeKcal: entry.1,
                                  note: note)
            context.insert(checkIn)
        }

        // An initial target snapshot reflecting the plan at the cut's start.
        let initial = MacroEngine.computeTarget(
            sex: .male,
            weightKg: startWeight,
            heightCm: 180,
            age: 34,
            bodyFatPercent: 20.0,
            activity: .moderate,
            goal: .cut,
            ratePercent: 0.6,
            dietStyle: .highProtein,
            formula: .mifflin,
            customProteinPerKg: 2.0,
            customFatPerKg: 0.8,
            roundTo: 10
        )
        let snapshot = TargetSnapshot(
            date: cal.date(byAdding: .day, value: -70, to: now) ?? now,
            calorieTarget: initial.calorieTarget,
            proteinG: initial.macros.proteinG,
            carbG: initial.macros.carbG,
            fatG: initial.macros.fatG,
            estimatedTDEE: initial.maintenanceTDEE,
            rationale: "Initial plan: high-protein 0.6%/week cut."
        )
        context.insert(snapshot)

        try? context.save()
    }
}
