import Foundation
import SwiftData
import SwiftUI

/// First-launch seeding: 4 built-in presets + a deep history of sessions so
/// streaks and insights look alive on day one. Gated behind `didSeed`.
enum SeedData {

    static func builtInPresets() -> [Preset] {
        [
            Preset(name: "Quick Reset", durationMin: 5, warmupSec: 10, intervalMin: 0,
                   ambient: .none, bellSound: .bowl, isBuiltIn: true, sortOrder: 0),
            Preset(name: "Daily Sit", durationMin: 20, warmupSec: 30, intervalMin: 0,
                   ambient: .brownNoise, bellSound: .bowl, isBuiltIn: true, sortOrder: 1),
            Preset(name: "Deep Sit", durationMin: 45, warmupSec: 30, intervalMin: 15,
                   ambient: .none, bellSound: .bowl, isBuiltIn: true, sortOrder: 2),
            Preset(name: "Open Sit", durationMin: 0, warmupSec: 15, intervalMin: 0,
                   ambient: .brownNoise, bellSound: .bowl, isBuiltIn: true, sortOrder: 3)
        ]
    }

    /// Seed presets + ~60 historical sessions over the last ~8 weeks.
    static func seedIfNeeded(context: ModelContext, didSeed: Bool) -> Bool {
        guard !didSeed else { return didSeed }

        for p in builtInPresets() { context.insert(p) }

        let names = ["Quick Reset", "Daily Sit", "Deep Sit", "Open Sit", "Daily Sit"]
        let moods = Mood.allCases
        let notes = [
            "", "", "Mind was busy but settled.", "", "Felt the breath deepen.",
            "", "Restless start, calm finish.", "", "Grateful for the quiet.",
            "", "Sat through some tension.", "", "Easy and light today."
        ]

        let cal = Calendar.current
        var rng = SystemRandomNumberGenerator()
        var sessions: [MeditationSession] = []

        // 56 days back; skip a few to make the streak realistic (not perfect).
        for dayOffset in 0..<56 {
            // ~78% chance of a sit on a given day; recent days denser.
            let skipChance = dayOffset < 14 ? 0.12 : 0.28
            if Double.random(in: 0...1, using: &rng) < skipChance { continue }

            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            // 1–2 sits per active day.
            let sits = Double.random(in: 0...1, using: &rng) < 0.25 ? 2 : 1
            for _ in 0..<sits {
                let hour = [6, 7, 8, 12, 18, 21, 22].randomElement(using: &rng) ?? 8
                let minute = Int.random(in: 0...59, using: &rng)
                var comps = cal.dateComponents([.year, .month, .day], from: day)
                comps.hour = hour
                comps.minute = minute
                let date = cal.date(from: comps) ?? day

                let durMin = [5, 10, 15, 20, 20, 25, 30, 45].randomElement(using: &rng) ?? 20
                // Most sits complete; some end early.
                let full = Double.random(in: 0...1, using: &rng) < 0.85
                let actualSec = full ? durMin * 60 : Int(Double(durMin * 60) * Double.random(in: 0.4...0.9, using: &rng))

                let s = MeditationSession(
                    date: date,
                    durationSec: max(60, actualSec),
                    presetName: names.randomElement(using: &rng) ?? "Daily Sit",
                    mood: moods.randomElement(using: &rng) ?? .calm,
                    note: notes.randomElement(using: &rng) ?? "",
                    completedFully: full
                )
                sessions.append(s)
            }
        }

        for s in sessions { context.insert(s) }
        try? context.save()
        return true
    }

    /// Wipe everything and re-seed (Settings reset action).
    static func reset(context: ModelContext) {
        try? context.delete(model: MeditationSession.self)
        try? context.delete(model: Preset.self)
        _ = seedIfNeeded(context: context, didSeed: false)
    }
}
