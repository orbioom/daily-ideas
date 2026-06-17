import Foundation
import SwiftData

/// Seeds bundled workouts and realistic past sessions on first launch.
/// Idempotent: guarded by a count check and the caller's didSeed flag.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        // Belt-and-braces: only seed into an empty store.
        let workoutCount = (try? context.fetchCount(FetchDescriptor<SwimWorkout>())) ?? 0
        let sessionCount = (try? context.fetchCount(FetchDescriptor<SwimSession>())) ?? 0
        if workoutCount == 0 {
            seedWorkouts(context: context)
        }
        if sessionCount == 0 {
            seedSessions(context: context)
        }
        try? context.save()
        didSeed = true
    }

    /// Insert the built-in workout templates.
    static func seedWorkouts(context: ModelContext) {
        for spec in BuiltInWorkouts.all() {
            context.insert(BuiltInWorkouts.makeWorkout(from: spec))
        }
    }

    /// Insert ~15 past sessions spread over recent weeks, 50+ completed sets total.
    static func seedSessions(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let plans = sessionPlans()

        for (offsetDays, plan) in plans {
            guard let date = calendar.date(byAdding: .day, value: -offsetDays, to: now) else { continue }
            let session = SwimSession(date: date,
                                      poolLengthMeters: 25,
                                      notes: plan.notes,
                                      workoutName: plan.workoutName)
            var totalDistance = 0.0
            var totalTime = 0.0
            var totalRest = 0.0
            for (index, s) in plan.sets.enumerated() {
                let dist = Double(s.repeats) * s.distance
                let swimTime = WorkoutMath.estimatedRepSeconds(distanceMeters: s.distance,
                                                               stroke: s.stroke,
                                                               effort: s.effort) * Double(s.repeats)
                // Apply a small per-session variation so pace trends look natural.
                let jitter = 1.0 + (Double((offsetDays % 7)) - 3.0) * 0.012
                let actual = max(1, swimTime * jitter)
                let completed = CompletedSet(order: index,
                                             stroke: s.stroke,
                                             repeats: s.repeats,
                                             distancePerRepMeters: s.distance,
                                             actualTimeSeconds: actual,
                                             restSeconds: s.rest,
                                             strokeCountPerLength: s.strokes)
                completed.session = session
                session.sets.append(completed)
                totalDistance += dist
                totalTime += actual
                totalRest += Double(s.rest * s.repeats)
            }
            session.totalDistanceMeters = totalDistance
            session.durationSeconds = Int((totalTime + totalRest).rounded())
            session.rpe = plan.rpe
            context.insert(session)
        }
    }

    /// Remove all workouts and sessions (cascades to their sets).
    static func clearAll(context: ModelContext) {
        if let workouts = try? context.fetch(FetchDescriptor<SwimWorkout>()) {
            for w in workouts { context.delete(w) }
        }
        if let sessions = try? context.fetch(FetchDescriptor<SwimSession>()) {
            for s in sessions { context.delete(s) }
        }
        try? context.save()
    }

    // MARK: - Plans

    private struct PlanSet {
        let repeats: Int
        let distance: Double
        let stroke: Stroke
        let effort: Effort
        let rest: Int
        let strokes: Int?
        init(_ repeats: Int, _ distance: Double, _ stroke: Stroke,
             _ effort: Effort = .moderate, rest: Int = 15, strokes: Int? = nil) {
            self.repeats = repeats
            self.distance = distance
            self.stroke = stroke
            self.effort = effort
            self.rest = rest
            self.strokes = strokes
        }
    }

    private struct Plan {
        let workoutName: String?
        let notes: String
        let rpe: Int?
        let sets: [PlanSet]
    }

    /// (daysAgo, plan) — 15 sessions across ~8 weeks.
    private static func sessionPlans() -> [(Int, Plan)] {
        [
            (2, Plan(workoutName: "Endurance 2000m", notes: "Felt strong, even splits.", rpe: 6, sets: [
                PlanSet(1, 400, .freestyle, .easy, rest: 30, strokes: 16),
                PlanSet(4, 50, .drill, .easy),
                PlanSet(5, 200, .freestyle, .moderate, rest: 20, strokes: 17),
                PlanSet(4, 50, .freestyle, .hard, rest: 15, strokes: 18),
                PlanSet(1, 200, .choice, .easy, rest: 0)
            ])),
            (4, Plan(workoutName: "Sprint 1500m", notes: "Legs heavy but good speed.", rpe: 8, sets: [
                PlanSet(1, 300, .freestyle, .easy, rest: 30),
                PlanSet(6, 50, .kick, .moderate),
                PlanSet(8, 50, .freestyle, .race, rest: 30, strokes: 19),
                PlanSet(4, 25, .butterfly, .hard, rest: 20),
                PlanSet(1, 200, .choice, .easy, rest: 0)
            ])),
            (6, Plan(workoutName: nil, notes: "Free swim, easy recovery.", rpe: 3, sets: [
                PlanSet(1, 800, .freestyle, .easy, rest: 0, strokes: 16),
                PlanSet(4, 50, .backstroke, .easy)
            ])),
            (9, Plan(workoutName: "Technique 1200m", notes: "Counted strokes, dropped two.", rpe: 4, sets: [
                PlanSet(1, 200, .freestyle, .easy, rest: 30, strokes: 17),
                PlanSet(6, 50, .drill, .easy),
                PlanSet(4, 50, .backstroke, .easy),
                PlanSet(4, 50, .breaststroke, .easy),
                PlanSet(6, 50, .freestyle, .moderate, strokes: 15),
                PlanSet(1, 100, .choice, .easy, rest: 0)
            ])),
            (11, Plan(workoutName: "Mixed IM 1800m", notes: "IM is humbling.", rpe: 7, sets: [
                PlanSet(1, 300, .im, .easy, rest: 40),
                PlanSet(4, 100, .im, .moderate, rest: 20),
                PlanSet(4, 75, .butterfly, .hard, rest: 25),
                PlanSet(4, 75, .backstroke, .moderate, rest: 20, strokes: 14),
                PlanSet(4, 75, .breaststroke, .moderate, rest: 20),
                PlanSet(1, 200, .freestyle, .easy, rest: 0)
            ])),
            (14, Plan(workoutName: "Endurance 2000m", notes: "Long aerobic day.", rpe: 6, sets: [
                PlanSet(1, 400, .freestyle, .easy, rest: 30, strokes: 16),
                PlanSet(4, 50, .drill, .easy),
                PlanSet(5, 200, .freestyle, .moderate, rest: 20, strokes: 18),
                PlanSet(4, 50, .freestyle, .hard, rest: 15),
                PlanSet(1, 200, .choice, .easy, rest: 0)
            ])),
            (16, Plan(workoutName: nil, notes: "Quick lunch swim.", rpe: 5, sets: [
                PlanSet(10, 100, .freestyle, .moderate, rest: 20, strokes: 17)
            ])),
            (18, Plan(workoutName: "Sprint 1500m", notes: "Best 50 in months.", rpe: 9, sets: [
                PlanSet(1, 300, .freestyle, .easy, rest: 30),
                PlanSet(6, 50, .kick, .moderate),
                PlanSet(8, 50, .freestyle, .race, rest: 30, strokes: 20),
                PlanSet(4, 25, .butterfly, .hard, rest: 20),
                PlanSet(1, 200, .choice, .easy, rest: 0)
            ])),
            (21, Plan(workoutName: "Technique 1200m", notes: "Smooth catch work.", rpe: 4, sets: [
                PlanSet(1, 200, .freestyle, .easy, rest: 30, strokes: 18),
                PlanSet(6, 50, .drill, .easy),
                PlanSet(4, 50, .backstroke, .easy),
                PlanSet(4, 50, .breaststroke, .easy),
                PlanSet(6, 50, .freestyle, .moderate, strokes: 16),
                PlanSet(1, 100, .choice, .easy, rest: 0)
            ])),
            (24, Plan(workoutName: nil, notes: "Open water prep, long free.", rpe: 6, sets: [
                PlanSet(1, 1500, .freestyle, .moderate, rest: 0, strokes: 18)
            ])),
            (28, Plan(workoutName: "Mixed IM 1800m", notes: "Solid all-around.", rpe: 7, sets: [
                PlanSet(1, 300, .im, .easy, rest: 40),
                PlanSet(4, 100, .im, .moderate, rest: 20),
                PlanSet(4, 75, .butterfly, .hard, rest: 25),
                PlanSet(4, 75, .backstroke, .moderate, rest: 20),
                PlanSet(4, 75, .breaststroke, .moderate, rest: 20),
                PlanSet(1, 200, .freestyle, .easy, rest: 0)
            ])),
            (33, Plan(workoutName: "Endurance 2000m", notes: "Negative split the main set.", rpe: 6, sets: [
                PlanSet(1, 400, .freestyle, .easy, rest: 30, strokes: 17),
                PlanSet(4, 50, .drill, .easy),
                PlanSet(5, 200, .freestyle, .moderate, rest: 20, strokes: 19),
                PlanSet(4, 50, .freestyle, .hard, rest: 15),
                PlanSet(1, 200, .choice, .easy, rest: 0)
            ])),
            (38, Plan(workoutName: nil, notes: "Recovery swim, kept it light.", rpe: 3, sets: [
                PlanSet(1, 600, .freestyle, .easy, rest: 0, strokes: 16),
                PlanSet(4, 50, .backstroke, .easy)
            ])),
            (45, Plan(workoutName: "Sprint 1500m", notes: "Building back speed.", rpe: 8, sets: [
                PlanSet(1, 300, .freestyle, .easy, rest: 30),
                PlanSet(6, 50, .kick, .moderate),
                PlanSet(8, 50, .freestyle, .race, rest: 30, strokes: 21),
                PlanSet(4, 25, .butterfly, .hard, rest: 20),
                PlanSet(1, 200, .choice, .easy, rest: 0)
            ])),
            (52, Plan(workoutName: "Technique 1200m", notes: "First swim back after travel.", rpe: 5, sets: [
                PlanSet(1, 200, .freestyle, .easy, rest: 30, strokes: 19),
                PlanSet(6, 50, .drill, .easy),
                PlanSet(4, 50, .backstroke, .easy),
                PlanSet(4, 50, .breaststroke, .easy),
                PlanSet(6, 50, .freestyle, .moderate, strokes: 17),
                PlanSet(1, 100, .choice, .easy, rest: 0)
            ]))
        ]
    }
}
