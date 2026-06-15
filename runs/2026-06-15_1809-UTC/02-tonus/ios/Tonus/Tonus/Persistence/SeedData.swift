import Foundation
import SwiftData

/// Seeds the built-in programs plus a believable history on first launch so Today and Insights
/// look alive immediately. Gated by a flag so it only ever runs once.
enum SeedData {
    private static let seededKey = "didSeedTonus"

    /// The canonical built-in programs, spread across levels.
    static func builtInPrograms() -> [TrainingProgram] {
        [
            TrainingProgram(name: "Gentle Start", level: 1,
                            summary: "A soft introduction — short squeezes with plenty of rest. Ideal for postpartum recovery or your very first sessions.",
                            contractSeconds: 3, holdSeconds: 0, relaxSeconds: 4, restSeconds: 20,
                            reps: 8, sets: 1, isBuiltIn: true, sortIndex: 0),
            TrainingProgram(name: "Quick", level: 1,
                            summary: "A 60-second reset you can do anywhere, any time. Great for building the daily habit.",
                            contractSeconds: 2, holdSeconds: 1, relaxSeconds: 3, restSeconds: 0,
                            reps: 10, sets: 1, isBuiltIn: true, sortIndex: 1),
            TrainingProgram(name: "Foundation", level: 2,
                            summary: "Balanced contract-and-relax work to build steady control and awareness.",
                            contractSeconds: 4, holdSeconds: 2, relaxSeconds: 4, restSeconds: 25,
                            reps: 10, sets: 2, isBuiltIn: true, sortIndex: 2),
            TrainingProgram(name: "Endurance", level: 3,
                            summary: "Longer holds to grow stamina in the slow-twitch fibres. Steady breathing throughout.",
                            contractSeconds: 3, holdSeconds: 8, relaxSeconds: 6, restSeconds: 30,
                            reps: 8, sets: 2, isBuiltIn: true, sortIndex: 3),
            TrainingProgram(name: "Strength", level: 3,
                            summary: "Higher reps with firm squeezes to build power. For experienced trainers.",
                            contractSeconds: 4, holdSeconds: 4, relaxSeconds: 4, restSeconds: 30,
                            reps: 12, sets: 3, isBuiltIn: true, sortIndex: 4),
            TrainingProgram(name: "Calm & Control", level: 2,
                            summary: "A mindful blend of measured squeezes and full releases to pair training with the breath.",
                            contractSeconds: 3, holdSeconds: 3, relaxSeconds: 5, restSeconds: 25,
                            reps: 9, sets: 2, isBuiltIn: true, sortIndex: 5),
            TrainingProgram(name: "Power Set", level: 4,
                            summary: "An advanced, demanding pattern — long holds, firm squeezes, three full sets.",
                            contractSeconds: 5, holdSeconds: 6, relaxSeconds: 5, restSeconds: 35,
                            reps: 10, sets: 3, isBuiltIn: true, sortIndex: 6)
        ]
    }

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        // If programs already exist (user-created before flag set), don't double-seed programs.
        let programDescriptor = FetchDescriptor<TrainingProgram>()
        let existingPrograms = (try? context.fetch(programDescriptor)) ?? []
        if existingPrograms.isEmpty {
            for program in builtInPrograms() {
                context.insert(program)
            }
        }

        // Seed history only if there are no logs yet.
        let logDescriptor = FetchDescriptor<SessionLog>()
        let existingLogs = (try? context.fetch(logDescriptor)) ?? []
        if existingLogs.isEmpty {
            for log in sampleHistory() {
                context.insert(log)
            }
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// 50+ realistic past sessions across ~8 weeks, with a believable current streak.
    private static func sampleHistory() -> [SessionLog] {
        var logs: [SessionLog] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // A deterministic pseudo-random sequence (no Foundation RNG needed) for stable seeds.
        var seedState: UInt64 = 0x9E3779B97F4A7C15
        func nextUnit() -> Double {
            seedState ^= seedState << 13
            seedState ^= seedState >> 7
            seedState ^= seedState << 17
            return Double(seedState % 10_000) / 10_000.0
        }

        // Program profiles to vary names/durations realistically.
        let profiles: [(name: String, reps: Int, baseSeconds: Int)] = [
            ("Gentle Start", 8, 200),
            ("Quick", 10, 60),
            ("Foundation", 20, 320),
            ("Endurance", 16, 360),
            ("Strength", 36, 420),
            ("Calm & Control", 18, 300)
        ]

        // Walk back ~56 days. Higher chance to train; keep the last ~5 days unbroken for a streak.
        for offset in 0..<56 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let recent = offset <= 4                 // guarantee a clean recent streak
            let trains = recent || nextUnit() < 0.74 // ~74% of days otherwise

            if !trains { continue }

            let sessionsToday = (nextUnit() < 0.22 && !recent) ? 2 : 1
            for _ in 0..<sessionsToday {
                let p = profiles[Int(nextUnit() * Double(profiles.count)) % profiles.count]
                // Add a little daytime offset so multiple sessions don't share a timestamp.
                let minuteOffset = Int(nextUnit() * 600)
                let date = calendar.date(byAdding: .minute, value: 8 * 60 + minuteOffset, to: day) ?? day

                // Occasionally an unfinished session (stopped early).
                // Guarantee finished sessions on the recent streak days; small abandon rate elsewhere.
                let finished = recent || nextUnit() > 0.08
                let completed = finished ? p.reps : max(1, Int(Double(p.reps) * (0.3 + nextUnit() * 0.4)))
                let durJitter = 1.0 + (nextUnit() - 0.5) * 0.2
                let duration = finished
                    ? Int(Double(p.baseSeconds) * durJitter)
                    : Int(Double(p.baseSeconds) * durJitter * (Double(completed) / Double(max(1, p.reps))))

                logs.append(SessionLog(
                    date: date,
                    programName: p.name,
                    completedReps: completed,
                    totalReps: p.reps,
                    durationSeconds: max(20, duration),
                    finished: finished
                ))
            }
        }
        return logs
    }
}
