import Foundation

// MARK: - EliminationProtocolTemplate

/// Template for creating a standard elimination protocol.
/// Phase 1: Remove top 7 allergens simultaneously for 21 days.
/// Phase 2: Challenge each food group for 3 days with 3-day rest periods.
/// Phase 3: Maintenance — avoid confirmed triggers.
enum EliminationProtocolTemplate {

    struct PhaseTemplate {
        let name: String
        let phaseType: PhaseType
        let durationDays: Int
        let foodsToAvoid: [String]
        let foodBeingChallenged: String?
        let description: String
        let instructions: [String]
    }

    /// All top allergens to eliminate in Phase 1
    static let eliminationFoods: [String] = [
        "Gluten", "Dairy", "Eggs", "Nuts", "Soy", "Corn", "Nightshades"
    ]

    /// Challenge groups with display names
    static let challengeGroups: [(name: String, foods: [String])] = [
        ("Gluten", ["wheat bread", "pasta", "crackers", "cereal"]),
        ("Dairy", ["milk", "cheese", "yogurt", "butter"]),
        ("Eggs", ["scrambled eggs", "fried eggs", "eggs"]),
        ("Nuts", ["almonds", "walnuts", "cashews", "peanuts"]),
        ("Soy", ["tofu", "edamame", "soy milk", "miso"]),
        ("Corn", ["corn tortillas", "popcorn", "corn chips"]),
        ("Nightshades", ["tomatoes", "bell peppers", "eggplant", "potatoes"]),
    ]

    static let phase1: PhaseTemplate = PhaseTemplate(
        name: "Elimination Phase",
        phaseType: .eliminate,
        durationDays: 21,
        foodsToAvoid: eliminationFoods,
        foodBeingChallenged: nil,
        description: "Remove all top allergens simultaneously for 21 days to establish a clean baseline.",
        instructions: [
            "Avoid all gluten, dairy, eggs, nuts, soy, corn, and nightshades.",
            "Eat from the Safe/Neutral food list in the Library.",
            "Log every meal and any symptoms you experience.",
            "Note your energy, digestion, and skin changes daily.",
            "After 21 days, proceed to the Challenge Phase.",
        ]
    )

    static func challengePhase(food: String) -> PhaseTemplate {
        PhaseTemplate(
            name: "Challenge: \(food)",
            phaseType: .challenge,
            durationDays: 3,
            foodsToAvoid: eliminationFoods.filter { $0 != food },
            foodBeingChallenged: food,
            description: "Reintroduce \(food) exclusively for 3 days while continuing to avoid all other eliminated foods.",
            instructions: [
                "Eat \(food) at least 2–3 times per day for 3 days.",
                "Continue avoiding all other eliminated foods.",
                "Log every meal and any symptoms within 48 hours.",
                "After 3 days, take a 3-day rest before the next challenge.",
                "If symptoms appear, \(food) is likely a trigger.",
            ]
        )
    }

    static func restPhase(afterFood: String) -> PhaseTemplate {
        PhaseTemplate(
            name: "Rest Period",
            phaseType: .rest,
            durationDays: 3,
            foodsToAvoid: eliminationFoods,
            foodBeingChallenged: nil,
            description: "3-day washout period after challenging \(afterFood). Return to the elimination baseline.",
            instructions: [
                "Remove \(afterFood) from your diet again.",
                "Eat only from the Safe/Neutral food list.",
                "Allow your body to return to baseline before the next challenge.",
                "Continue logging symptoms to track recovery.",
            ]
        )
    }

    static let maintenancePhase: PhaseTemplate = PhaseTemplate(
        name: "Maintenance",
        phaseType: .maintenance,
        durationDays: 0,
        foodsToAvoid: [],
        foodBeingChallenged: nil,
        description: "Ongoing phase — avoid confirmed triggers and enjoy foods you tolerate well.",
        instructions: [
            "Continue avoiding foods identified as triggers.",
            "Keep logging meals and symptoms for ongoing tracking.",
            "Retest trigger foods every 6–12 months if desired.",
            "Work with your doctor to review the full report.",
        ]
    )

    /// Build the full standard protocol sequence starting from a given date.
    static func buildFullProtocol(startDate: Date) -> [EliminationPhase] {
        var phases: [EliminationPhase] = []
        var currentDate = startDate

        // Phase 1: Elimination (21 days)
        let elimPhase = EliminationPhase(
            name: phase1.name,
            startDate: currentDate,
            endDate: Calendar.current.date(byAdding: .day, value: phase1.durationDays, to: currentDate),
            phaseType: PhaseType.eliminate.rawValue,
            foodsToAvoid: eliminationFoods,
            foodBeingChallenged: nil,
            notes: phase1.description,
            isActive: true
        )
        phases.append(elimPhase)
        currentDate = Calendar.current.date(byAdding: .day, value: phase1.durationDays, to: currentDate) ?? currentDate

        // Phase 2: Challenge each food group + rest period
        for group in challengeGroups {
            let challenge = EliminationPhase(
                name: "Challenge: \(group.name)",
                startDate: currentDate,
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: currentDate),
                phaseType: PhaseType.challenge.rawValue,
                foodsToAvoid: eliminationFoods.filter { $0 != group.name },
                foodBeingChallenged: group.name,
                notes: "Reintroduce \(group.name) for 3 days.",
                isActive: false
            )
            phases.append(challenge)
            currentDate = Calendar.current.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate

            let rest = EliminationPhase(
                name: "Rest Period",
                startDate: currentDate,
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: currentDate),
                phaseType: PhaseType.rest.rawValue,
                foodsToAvoid: eliminationFoods,
                foodBeingChallenged: nil,
                notes: "3-day washout after challenging \(group.name).",
                isActive: false
            )
            phases.append(rest)
            currentDate = Calendar.current.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate
        }

        // Phase 3: Maintenance
        let maintenance = EliminationPhase(
            name: "Maintenance",
            startDate: currentDate,
            endDate: nil,
            phaseType: PhaseType.maintenance.rawValue,
            foodsToAvoid: [],
            foodBeingChallenged: nil,
            notes: "Avoid confirmed triggers. Continue tracking as needed.",
            isActive: false
        )
        phases.append(maintenance)

        return phases
    }
}
