import Foundation
import SwiftData

/// Seeds ~10 weeks of realistic past `DayLog`s on first launch so Calendar and Insights
/// are rich immediately. Gated by a flag and an empty-store check so a user who has begun
/// logging is never overwritten, and a true empty state is still reachable after a reset.
enum SeedData {
    private static let seededKey = "didSeedDayLogs"

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        let existing = DayLogStore.allLogs(context: context)
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Deterministic pseudo-random so the seeded picture is consistent and plausible.
        var rng = SeededGenerator(seed: 0xE471_0A55)

        // 72 days (~10+ weeks) of history, ending yesterday (today is the user's to log).
        let totalDays = 72

        // Build irregular, lengthening cycles: period episodes start at these day-offsets
        // (counted back from today). Gaps widen — 24, 27, 33, 41, 58 — to read as perimenopause.
        // Offsets are "days ago" for the first day of each bleed; each bleed lasts 3–5 days.
        let episodeOffsets = [70, 46, 19] // three periods over the window, widening gaps
        var bleedDays: [Int: Flow] = [:] // dayOffset(ago) -> flow
        for start in episodeOffsets {
            let length = 3 + Int(rng.next() % 3) // 3–5 days
            for i in 0..<length {
                let off = start - i
                guard off >= 0 else { continue }
                let flow: Flow
                switch i {
                case 0: flow = .spotting
                case 1: flow = .heavy
                case 2: flow = .medium
                default: flow = .light
                }
                bleedDays[off] = flow
            }
        }

        for offset in stride(from: totalDays, through: 1, by: -1) {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }

            // Skip ~12% of days to keep an authentic, gappy log (and to exercise empty cells).
            if rng.next() % 100 < 12 { continue }

            // Hot flashes: a gentle upward drift over the window plus daily noise.
            let drift = Double(totalDays - offset) / Double(totalDays) // 0..1, rising toward today
            let base = 2.0 + drift * 4.0
            let noise = Double(Int(rng.next() % 5)) - 2.0
            let hotFlashes = max(0, Int((base + noise).rounded()))

            let nightSweats = rng.next() % 100 < (25 + Int(drift * 30))

            // Mood/sleep/energy: poorer on high-hot-flash days (gives the correlation signal).
            let stress = min(3, hotFlashes / 2)
            let mood = clamp(4 - stress + jitter(&rng))
            let sleep = clamp(4 - (nightSweats ? 2 : 0) - stress / 2 + jitter(&rng))
            let energy = clamp(sleep - jitterSmall(&rng))

            // Symptoms — pick a plausible handful weighted by the day's state.
            var symptoms: [String: Int] = [:]
            if hotFlashes >= 1 { symptoms["hot_flashes"] = min(3, max(1, hotFlashes / 2)) }
            if nightSweats { symptoms["night_sweats"] = 1 + Int(rng.next() % 2) }
            if sleep <= 2 { symptoms["sleep_problems"] = 2 + Int(rng.next() % 2) }
            if rng.next() % 100 < 40 { symptoms["fatigue"] = 1 + Int(rng.next() % 2) }
            if rng.next() % 100 < 30 { symptoms["brain_fog"] = 1 + Int(rng.next() % 2) }
            if rng.next() % 100 < 28 { symptoms["mood_swings"] = 1 + Int(rng.next() % 2) }
            if rng.next() % 100 < 22 { symptoms["anxiety"] = 1 + Int(rng.next() % 2) }
            if rng.next() % 100 < 25 { symptoms["joint_aches"] = 1 + Int(rng.next() % 2) }
            if rng.next() % 100 < 12 { symptoms["headaches"] = 1 + Int(rng.next() % 2) }
            if rng.next() % 100 < 18 { symptoms["irritability"] = 1 + Int(rng.next() % 2) }

            // Treatments — a stable-ish daily supplement routine plus occasional extras.
            var treatments: [String] = []
            if rng.next() % 100 < 70 { treatments.append("Vitamin D") }
            if rng.next() % 100 < 55 { treatments.append("Magnesium") }
            if drift > 0.5 && rng.next() % 100 < 30 { treatments.append("Black cohosh") }
            if rng.next() % 100 < 15 { treatments.append("Omega-3") }

            let flow = bleedDays[offset] ?? .none

            let notes: String
            if hotFlashes >= 6 {
                notes = "Rough day for flashes — afternoon was the worst."
            } else if nightSweats {
                notes = "Woke up damp around 3am."
            } else {
                notes = ""
            }

            let log = DayLog(date: date,
                             hotFlashCount: hotFlashes,
                             nightSweats: nightSweats,
                             mood: mood,
                             sleepQuality: sleep,
                             energy: energy,
                             flow: flow,
                             symptoms: symptoms,
                             treatments: treatments,
                             notes: notes)
            context.insert(log)
        }

        DayLogStore.save(context)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: - Helpers

    private static func clamp(_ v: Int) -> Int { min(5, max(1, v)) }
    private static func jitter(_ rng: inout SeededGenerator) -> Int { Int(rng.next() % 3) - 1 } // -1..1
    private static func jitterSmall(_ rng: inout SeededGenerator) -> Int { Int(rng.next() % 2) } // 0..1
}

/// Tiny deterministic LCG so seeded data is reproducible without importing anything.
struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9 : seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state >> 16
    }
}
