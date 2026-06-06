import Foundation
import SwiftData

/// Seeds a handful of plausible starter routines on first launch, and provides
/// in-memory previews. All routines are runnable (>= 1 segment).
enum SampleData {

    /// Insert starter routines into the live store. Called once, guarded by a flag.
    static func insert(into context: ModelContext) {
        for routine in makeRoutines() {
            context.insert(routine)
        }
        try? context.save()
    }

    /// Build (but do not insert) the starter routines.
    static func makeRoutines() -> [Routine] {
        [
            classicHIIT(),
            tabata(),
            morningMobility(),
            emom(),
            coreFinisher(),
            sevenMinute()
        ]
    }

    // MARK: - Routine builders

    private static func classicHIIT() -> Routine {
        let r = Routine(name: "Classic HIIT",
                        glyph: "bolt.fill",
                        note: "Warm up, eight rounds of work and rest, then cool down.")
        var segs: [Segment] = []
        var order = 0
        segs.append(Segment(order: order, kind: .prepare, duration: 60, label: "Warm up")); order += 1
        let group = UUID()
        segs.append(Segment(order: order, kind: .work, duration: 40, label: "Work",
                            repeatGroupID: group, repeatCount: 8)); order += 1
        segs.append(Segment(order: order, kind: .rest, duration: 20, label: "Rest",
                            repeatGroupID: group, repeatCount: 8)); order += 1
        segs.append(Segment(order: order, kind: .cooldown, duration: 90, label: "Cooldown")); order += 1
        r.segments = segs
        return r
    }

    private static func tabata() -> Routine {
        let r = Routine(name: "Tabata",
                        glyph: "flame.fill",
                        note: "The canonical 20-on / 10-off, eight rounds.")
        var segs: [Segment] = []
        var order = 0
        segs.append(Segment(order: order, kind: .prepare, duration: 15, label: "Get ready")); order += 1
        let group = UUID()
        segs.append(Segment(order: order, kind: .work, duration: 20, label: "All out",
                            repeatGroupID: group, repeatCount: 8)); order += 1
        segs.append(Segment(order: order, kind: .rest, duration: 10, label: "Rest",
                            repeatGroupID: group, repeatCount: 8)); order += 1
        segs.append(Segment(order: order, kind: .cooldown, duration: 60, label: "Breathe")); order += 1
        r.segments = segs
        return r
    }

    private static func morningMobility() -> Routine {
        let r = Routine(name: "Morning Mobility",
                        glyph: "figure.cooldown",
                        note: "A calm flow of held stretches to start the day.")
        var segs: [Segment] = []
        var order = 0
        segs.append(Segment(order: order, kind: .prepare, duration: 20, label: "Settle in")); order += 1
        let group = UUID()
        segs.append(Segment(order: order, kind: .work, duration: 45, label: "Hold stretch",
                            repeatGroupID: group, repeatCount: 6)); order += 1
        segs.append(Segment(order: order, kind: .rest, duration: 15, label: "Switch sides",
                            repeatGroupID: group, repeatCount: 6)); order += 1
        segs.append(Segment(order: order, kind: .cooldown, duration: 60, label: "Stillness")); order += 1
        r.segments = segs
        return r
    }

    private static func emom() -> Routine {
        let r = Routine(name: "EMOM 10",
                        glyph: "stopwatch.fill",
                        note: "Every minute on the minute for ten minutes.")
        var segs: [Segment] = []
        var order = 0
        segs.append(Segment(order: order, kind: .prepare, duration: 30, label: "Set up")); order += 1
        let group = UUID()
        segs.append(Segment(order: order, kind: .work, duration: 60, label: "Minute set",
                            repeatGroupID: group, repeatCount: 10)); order += 1
        segs.append(Segment(order: order, kind: .cooldown, duration: 90, label: "Cooldown")); order += 1
        r.segments = segs
        return r
    }

    private static func coreFinisher() -> Routine {
        let r = Routine(name: "Core Finisher",
                        glyph: "figure.core.training",
                        note: "A short, sharp three-round core burner.")
        var segs: [Segment] = []
        var order = 0
        let group = UUID()
        segs.append(Segment(order: order, kind: .work, duration: 30, label: "Plank",
                            repeatGroupID: group, repeatCount: 3)); order += 1
        segs.append(Segment(order: order, kind: .work, duration: 30, label: "Hollow hold",
                            repeatGroupID: group, repeatCount: 3)); order += 1
        segs.append(Segment(order: order, kind: .rest, duration: 20, label: "Rest",
                            repeatGroupID: group, repeatCount: 3)); order += 1
        r.segments = segs
        return r
    }

    private static func sevenMinute() -> Routine {
        let r = Routine(name: "Seven Minute",
                        glyph: "timer",
                        note: "Twelve bodyweight stations, 30 on / 10 off.")
        var segs: [Segment] = []
        var order = 0
        segs.append(Segment(order: order, kind: .prepare, duration: 15, label: "Ready")); order += 1
        let group = UUID()
        segs.append(Segment(order: order, kind: .work, duration: 30, label: "Station",
                            repeatGroupID: group, repeatCount: 12)); order += 1
        segs.append(Segment(order: order, kind: .rest, duration: 10, label: "Switch",
                            repeatGroupID: group, repeatCount: 12)); order += 1
        r.segments = segs
        return r
    }

    // MARK: - Preview container

    /// A throwaway in-memory container pre-seeded with sample data for `#Preview`.
    /// Returns nil only if an in-memory store cannot be created (previews then show
    /// an empty state rather than crashing).
    @MainActor
    static func previewContainer() -> ModelContainer? {
        let schema = Schema([Routine.self, Segment.self, Session.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: config) else {
            return nil
        }
        let context = container.mainContext
        let routines = makeRoutines()
        for routine in routines { context.insert(routine) }
        // Add a couple of sample sessions to the first routine for History previews.
        if let first = routines.first {
            let now = Date.now
            let s1 = Session(startedAt: now.addingTimeInterval(-3600),
                             endedAt: now.addingTimeInterval(-3000),
                             activeSeconds: 600, workSeconds: 320,
                             completedSteps: first.stepCount, totalSteps: first.stepCount,
                             finishedFully: true, routineNameSnapshot: first.displayName)
            let s2 = Session(startedAt: now.addingTimeInterval(-86400),
                             endedAt: now.addingTimeInterval(-86100),
                             activeSeconds: 300, workSeconds: 160,
                             completedSteps: max(1, first.stepCount / 2), totalSteps: first.stepCount,
                             finishedFully: false, routineNameSnapshot: first.displayName)
            s1.routine = first
            s2.routine = first
            context.insert(s1)
            context.insert(s2)
        }
        try? context.save()
        return container
    }
}
