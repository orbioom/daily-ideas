import Foundation
import SwiftData

/// Seeds 1–2 example profiles on first launch so Home and Compatibility look alive,
/// while preserving a true empty-state path (only seeds when the store is empty AND
/// onboarding hasn't completed — i.e. genuinely first run).
enum SeedData {
    private static let seededKey = "didSeedProfiles"

    /// Build a deterministic set of responses that lands a profile near a target band per trait.
    /// `targets` are desired normalized scores 0–100; we choose Likert answers to approximate them.
    private static func responses(targets: [Trait: Double]) -> [Int: Int] {
        var responses: [Int: Int] = [:]
        for trait in Trait.allCases {
            let target = targets[trait] ?? 50
            // Desired recoded average per item (1–5) so that normalized ≈ target.
            // normalized = (sum - 8)/32 * 100, sum = 8*avg → avg = target/100*4 + 1
            let avg = (target / 100.0) * 4.0 + 1.0
            let likertForPositive = Int(avg.rounded())
            let clampedPos = min(5, max(1, likertForPositive))
            for item in ItemBank.items where item.trait == trait {
                // For a positively keyed item, answer = recoded value directly.
                // For a reverse-keyed item, raw answer = 6 - recoded to land same recoded value.
                let answer = item.keyedPositive ? clampedPos : (6 - clampedPos)
                responses[item.id] = min(5, max(1, answer))
            }
        }
        return responses
    }

    static func seedIfNeeded(context: ModelContext) {
        // Only seed once, ever.
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        // If there are already profiles (e.g. user created one), don't seed.
        let descriptor = FetchDescriptor<Profile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        // Two example comparison profiles (NOT primary) so the user's own first test still
        // shows a clean empty/CTA state on Home, but Profiles/Compatibility look populated.
        let avaResponses = responses(targets: [
            .openness: 78, .conscientiousness: 64, .extraversion: 70,
            .agreeableness: 82, .neuroticism: 58
        ])
        let avaResult = ScoringEngine.score(responses: avaResponses)
        let ava = Profile(name: "Ava (sample)", isPrimary: false, result: avaResult, responses: avaResponses)

        let noahResponses = responses(targets: [
            .openness: 45, .conscientiousness: 80, .extraversion: 35,
            .agreeableness: 55, .neuroticism: 30
        ])
        let noahResult = ScoringEngine.score(responses: noahResponses)
        let noah = Profile(name: "Noah (sample)", isPrimary: false, result: noahResult, responses: noahResponses)

        context.insert(ava)
        context.insert(noah)
        try? context.save()

        UserDefaults.standard.set(true, forKey: seededKey)
    }
}
