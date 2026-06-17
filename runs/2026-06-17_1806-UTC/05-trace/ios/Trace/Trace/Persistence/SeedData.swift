import Foundation
import SwiftData
import SwiftUI

/// Seeds a default profile and some sample progress the first time the app runs.
/// Guarded by an @AppStorage flag so it only ever runs once.
enum SeedData {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let didSeedKey = "didSeedDataV1"
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: didSeedKey) { return }

        // Only seed if there are truly no profiles (defensive against partial state).
        let existing = (try? context.fetch(FetchDescriptor<Profile>())) ?? []
        guard existing.isEmpty else {
            defaults.set(true, forKey: didSeedKey)
            return
        }

        let profile = Profile(name: "Sammy", colorHex: 0xFF8A4C, age: 4)
        context.insert(profile)

        // A handful of sample uppercase progress rows so Progress isn't empty.
        let samples: [(String, Int)] = [
            ("U_A", 3), ("U_B", 2), ("U_C", 3), ("U_D", 1),
            ("U_E", 2), ("U_O", 3), ("U_S", 1), ("U_T", 2),
            ("U_L", 3), ("U_I", 3)
        ]
        for (key, stars) in samples {
            let gp = GlyphProgress(
                profileID: profile.id,
                glyphKey: key,
                bestStars: stars,
                attempts: stars + 1,
                lastPracticed: Date.now.addingTimeInterval(-Double.random(in: 600...86_400))
            )
            context.insert(gp)
        }

        try? context.save()

        // Activate the seeded profile.
        defaults.set(profile.id.uuidString, forKey: "activeProfileID")
        defaults.set(true, forKey: didSeedKey)
    }
}
