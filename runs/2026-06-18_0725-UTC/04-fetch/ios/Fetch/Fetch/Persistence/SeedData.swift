import Foundation
import SwiftData

/// Seeds one realistic sample dog with progress + ~6 weeks of sessions on first run.
/// Guarded by an @AppStorage flag so it executes exactly once.
@MainActor
enum SeedData {

    static func seedIfNeeded(context: ModelContext, hasSeeded: inout Bool) {
        guard !hasSeeded else { return }
        // Extra guard: if any dog already exists, don't double-seed.
        let existing = (try? context.fetch(FetchDescriptor<Dog>())) ?? []
        if !existing.isEmpty {
            hasSeeded = true
            return
        }

        let cooper = Dog(
            name: "Cooper",
            breed: "Golden Retriever",
            birthdate: Calendar.current.date(byAdding: .month, value: -16, to: Date()),
            notes: "Food-motivated and eager to please. Working toward a reliable recall and some party tricks.",
            isActive: true
        )
        context.insert(cooper)

        // 12 progress rows across statuses.
        let plan: [(String, TrickStatus, Int, Int)] = [
            // trickId, status, sessionCount, lastPracticedDaysAgo
            ("name", .mastered, 6, 30),
            ("watch-me", .mastered, 5, 22),
            ("sit", .mastered, 7, 10),
            ("touch", .mastered, 4, 25),
            ("down", .practicing, 5, 2),
            ("come", .practicing, 6, 1),
            ("shake", .practicing, 4, 3),
            ("leave-it", .learning, 3, 4),
            ("spin", .learning, 2, 5),
            ("stay", .learning, 3, 1),
            ("drop-it", .learning, 2, 6),
            ("crate", .notStarted, 0, 0)
        ]

        let cal = Calendar.current
        for (trickId, status, count, daysAgo) in plan {
            let last: Date? = status == .notStarted
                ? nil
                : cal.date(byAdding: .day, value: -daysAgo, to: Date())
            let p = TrickProgress(
                dog: cooper,
                trickId: trickId,
                status: status,
                sessionCount: count,
                lastPracticed: last
            )
            context.insert(p)
        }

        // ~35 sessions across the past ~6 weeks (42 days). Deterministic but varied.
        let activeTricks = ["name", "watch-me", "sit", "touch", "down", "come", "shake", "leave-it", "spin", "stay", "drop-it"]
        let notes = [
            "Great focus today!",
            "A bit distracted but got there.",
            "Nailed it on the first few reps.",
            "Needed higher-value treats.",
            "Best session yet \u{2014} so proud.",
            "Short and sweet before dinner.",
            "",
            "Working on duration."
        ]

        var seed: UInt64 = 0x9E3779B97F4A7C15  // splitmix64 state
        func next() -> UInt64 {
            seed &+= 0x9E3779B97F4A7C15
            var z = seed
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        func rand(_ upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(next() % UInt64(upperBound))
        }

        var created = 0
        // Walk back 42 days; train on ~80% of days, sometimes twice, to build a streak.
        for dayOffset in 0..<42 {
            // Skip ~20% of days to make the streak realistic but present.
            if rand(10) < 2 && dayOffset > 0 { continue }
            guard let dayBase = cal.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            let sessionsThisDay = rand(10) < 3 ? 2 : 1
            for _ in 0..<sessionsThisDay {
                guard created < 36 else { break }
                let trickIndex = rand(activeTricks.count)
                let trickId = activeTricks[trickIndex]

                // A time of day between 7am and 8pm.
                let hour = 7 + rand(13)
                let minute = rand(60)
                var comps = cal.dateComponents([.year, .month, .day], from: dayBase)
                comps.hour = hour
                comps.minute = minute
                let date = cal.date(from: comps) ?? dayBase

                let duration = (3 + rand(8)) * 60          // 3..10 minutes
                let reps = 8 + rand(20)                     // 8..27 reps
                let rating = 3 + rand(3)                    // 3..5 (sample dog is doing well)
                let note = notes[rand(notes.count)]

                let s = TrainingSession(
                    dog: cooper,
                    trickId: trickId,
                    date: date,
                    durationSec: duration,
                    reps: reps,
                    successRating: rating,
                    note: note
                )
                context.insert(s)
                created += 1
            }
            if created >= 36 { break }
        }

        try? context.save()
        hasSeeded = true
    }
}
