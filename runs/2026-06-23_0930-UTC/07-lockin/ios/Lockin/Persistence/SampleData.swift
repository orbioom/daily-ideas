import Foundation
import SwiftData

/// Seeds projects, settings and 50+ realistic focus sessions on first launch.
enum SampleData {

    struct ProjectSeed {
        let name: String
        let hex: String
        let icon: String
        let goal: Int
    }

    static let projectSeeds: [ProjectSeed] = [
        .init(name: "Deep Work", hex: "7B51B8", icon: "target", goal: 120),
        .init(name: "Writing", hex: "E08F3A", icon: "pencil.and.outline", goal: 60),
        .init(name: "Study", hex: "3299A1", icon: "graduationcap.fill", goal: 90),
        .init(name: "Side Project", hex: "32A368", icon: "laptopcomputer", goal: 45),
        .init(name: "Reading", hex: "4A6FE0", icon: "book.closed.fill", goal: 30)
    ]

    static let tagPool = ["coding", "writing", "reading", "research", "design", "email", "planning", "review"]

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        // Settings row.
        let settingsCount = (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        if settingsCount == 0 {
            context.insert(AppSettings())
        }

        // Projects + sessions.
        let projectCount = (try? context.fetchCount(FetchDescriptor<Project>())) ?? 0
        guard projectCount == 0 else {
            try? context.save()
            return
        }

        var projects: [Project] = []
        for seed in projectSeeds {
            let p = Project(name: seed.name, colorHex: seed.hex, iconName: seed.icon, dailyGoalMinutes: seed.goal)
            context.insert(p)
            projects.append(p)
        }

        // Deterministic-ish pseudo random for reproducible-feeling sample data.
        var rng = SeededGenerator(seed: 20260623)
        let cal = Calendar.current
        let modes: [SessionMode] = [.pomodoro, .pomodoro, .pomodoro, .custom, .flow]
        var created = 0

        // Spread across the last 35 days; skip a few to make streaks realistic.
        for dayOffset in stride(from: 34, through: 0, by: -1) {
            // ~78% of days are active.
            if Int(rng.next() % 100) > 78 { continue }
            let sessionsToday = 1 + Int(rng.next() % 4) // 1...4
            for _ in 0..<sessionsToday {
                let mode = modes[Int(rng.next() % UInt64(modes.count))]
                let project = projects[Int(rng.next() % UInt64(projects.count))]
                let tag = tagPool[Int(rng.next() % UInt64(tagPool.count))]
                // Start hour weighted toward 8-18.
                let hour = 8 + Int(rng.next() % 11)
                let minute = Int(rng.next() % 60)
                let base = cal.date(byAdding: .day, value: -dayOffset, to: Date().startOfDay) ?? Date()
                let start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base

                let planned: Int
                let focused: Int
                let completed: Bool
                switch mode {
                case .pomodoro:
                    planned = 25 * 60
                    completed = (rng.next() % 100) > 18
                    focused = completed ? planned : Int(rng.next() % UInt64(planned - 120)) + 120
                case .custom:
                    let mins = [40, 50, 45, 30, 60][Int(rng.next() % 5)]
                    planned = mins * 60
                    completed = (rng.next() % 100) > 22
                    focused = completed ? planned : Int(rng.next() % UInt64(planned - 120)) + 120
                case .flow:
                    planned = 0
                    completed = true
                    focused = (15 + Int(rng.next() % 65)) * 60 // 15-80 min
                }
                let distractions = Int(rng.next() % 5)
                let end = start.addingTimeInterval(Double(focused) + Double(distractions) * 30)
                let session = FocusSession(
                    startedAt: start,
                    endedAt: end,
                    focusedSeconds: focused,
                    plannedSeconds: planned,
                    mode: mode,
                    tag: tag,
                    note: "",
                    wasCompleted: completed,
                    distractionCount: distractions,
                    project: project
                )
                context.insert(session)
                created += 1
            }
        }
        // Guarantee at least 50 items even if random skipping was aggressive.
        while created < 52 {
            let mode: SessionMode = .pomodoro
            let project = projects[created % projects.count]
            let dayOffset = created % 30
            let base = cal.date(byAdding: .day, value: -dayOffset, to: Date().startOfDay) ?? Date()
            let start = cal.date(bySettingHour: 9 + (created % 8), minute: 15, second: 0, of: base) ?? base
            let focused = 25 * 60
            let s = FocusSession(startedAt: start,
                                 endedAt: start.addingTimeInterval(Double(focused)),
                                 focusedSeconds: focused,
                                 plannedSeconds: focused,
                                 mode: mode,
                                 tag: tagPool[created % tagPool.count],
                                 wasCompleted: true,
                                 distractionCount: created % 3,
                                 project: project)
            context.insert(s)
            created += 1
        }

        try? context.save()
    }
}

/// Tiny SplitMix64 generator for reproducible sample data.
struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
