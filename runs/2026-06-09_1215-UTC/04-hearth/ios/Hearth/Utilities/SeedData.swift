import Foundation
import SwiftData

/// Seeds a realistic home on first launch so every screen — Today, Rooms,
/// Insights — has life in it. Guarded so it runs exactly once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Room>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date.now
        func daysAgo(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: -d, to: now) ?? now
        }

        // (name, symbol, colorIndex, [ (task, frequency, lastDoneDaysAgo?, estMinutes) ])
        // lastDoneDaysAgo nil = never done. Values scattered to create overdue,
        // due-today, and fresh tasks across the home.
        let spec: [(name: String, symbol: String, color: Int,
                    tasks: [(name: String, freq: Int, lastAgo: Int?, mins: Int)])] = [
            ("Kitchen", "fork.knife", 0, [
                ("Wipe counters", 1, 1, 5),
                ("Wash dishes", 1, 0, 10),
                ("Mop floor", 7, 9, 20),
                ("Clean fridge", 30, 26, 30),
                ("Clean oven", 60, 70, 45)
            ]),
            ("Bathroom", "shower", 1, [
                ("Clean toilet", 3, 4, 10),
                ("Wipe sink & mirror", 3, 1, 5),
                ("Scrub shower", 7, 8, 20),
                ("Deep clean", 14, 16, 40),
                ("Wash bath mat", 14, 14, 10)
            ]),
            ("Bedroom", "bed.double", 2, [
                ("Make bed", 1, 0, 3),
                ("Change sheets", 7, 6, 15),
                ("Dust surfaces", 10, 12, 10),
                ("Vacuum", 5, 5, 15)
            ]),
            ("Living Room", "sofa", 3, [
                ("Tidy & declutter", 1, 1, 10),
                ("Vacuum", 5, 6, 15),
                ("Dust shelves", 10, 9, 10),
                ("Clean windows", 60, 64, 30)
            ]),
            ("Entryway", "door.left.hand.open", 4, [
                ("Sweep floor", 3, 2, 5),
                ("Wipe doorknobs", 7, 11, 5),
                ("Organize shoes", 7, 4, 5)
            ]),
            ("Office", "desktopcomputer", 5, [
                ("Clear desk", 2, 3, 5),
                ("Dust electronics", 10, 13, 10),
                ("Vacuum", 7, 7, 10),
                ("Empty bin", 7, 5, 3)
            ])
        ]

        var rooms: [Room] = []
        for (rIdx, r) in spec.enumerated() {
            let room = Room(name: r.name, symbol: r.symbol, colorIndex: r.color, sortIndex: rIdx)
            context.insert(room)
            for (tIdx, t) in r.tasks.enumerated() {
                let last = t.lastAgo.map { daysAgo($0) }
                let task = CleaningTask(name: t.name,
                                        frequencyDays: t.freq,
                                        lastDone: last,
                                        estMinutes: t.mins,
                                        sortIndex: tIdx,
                                        roomName: r.name)
                task.room = room
                context.insert(task)
            }
            rooms.append(room)
        }

        // ~60 completion logs across the last ~6 weeks (42 days) so Insights look
        // real: weighted toward everyday chores, spread over most days.
        let logSamples: [(room: String, task: String, mins: Int)] = [
            ("Kitchen", "Wipe counters", 5), ("Kitchen", "Wash dishes", 10),
            ("Bedroom", "Make bed", 3), ("Living Room", "Tidy & declutter", 10),
            ("Bathroom", "Wipe sink & mirror", 5), ("Office", "Clear desk", 5),
            ("Entryway", "Sweep floor", 5), ("Bedroom", "Vacuum", 15),
            ("Bathroom", "Clean toilet", 10), ("Living Room", "Vacuum", 15),
            ("Office", "Empty bin", 3), ("Kitchen", "Mop floor", 20)
        ]
        var rng = SeededGenerator(seed: 0xBEEFCAFE1234)
        var inserted = 0
        var day = 41
        while day >= 0 && inserted < 60 {
            // 1–2 completions on most days; occasionally a rest day.
            let roll = Int.random(in: 0...3, using: &rng)
            let count = roll == 0 ? 0 : (roll == 3 ? 2 : 1)
            for _ in 0..<count {
                let sample = logSamples[Int.random(in: 0..<logSamples.count, using: &rng)]
                let log = CompletionLog(date: daysAgo(day),
                                        taskName: sample.task,
                                        roomName: sample.room,
                                        minutes: sample.mins)
                context.insert(log)
                inserted += 1
            }
            day -= 1
        }

        try? context.save()
    }
}

/// A tiny deterministic PRNG so seeded history is stable across launches/tests
/// without pulling in any dependency.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }
}
