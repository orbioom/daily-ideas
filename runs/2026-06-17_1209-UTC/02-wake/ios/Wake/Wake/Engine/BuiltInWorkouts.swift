import Foundation

/// Factory for the bundled starter workouts. Pure value description, turned into
/// @Model objects by the caller so they can be inserted into a context.
enum BuiltInWorkouts {

    /// A lightweight description of a set, used to build templates and seeds.
    struct SetSpec {
        let repeats: Int
        let distance: Double
        let stroke: Stroke
        let sendOff: Int
        let rest: Int
        let effort: Effort
        let note: String

        init(_ repeats: Int,
             _ distance: Double,
             _ stroke: Stroke,
             sendOff: Int = 0,
             rest: Int = 20,
             effort: Effort = .moderate,
             note: String = "") {
            self.repeats = repeats
            self.distance = distance
            self.stroke = stroke
            self.sendOff = sendOff
            self.rest = rest
            self.effort = effort
            self.note = note
        }
    }

    struct Spec {
        let name: String
        let type: WorkoutType
        let poolLength: Double
        let notes: String
        let sets: [SetSpec]

        var totalDistance: Double {
            sets.reduce(0) { $0 + Double($1.repeats) * $1.distance }
        }
    }

    static func all() -> [Spec] {
        [endurance2000, sprint1500, technique1200, mixedIM1800]
    }

    static let endurance2000 = Spec(
        name: "Endurance 2000m",
        type: .endurance,
        poolLength: 25,
        notes: "Steady aerobic base. Hold an even pace throughout the main set.",
        sets: [
            SetSpec(1, 400, .freestyle, rest: 30, effort: .easy, note: "Warm-up, smooth"),
            SetSpec(4, 50, .drill, rest: 20, effort: .easy, note: "Catch-up drill"),
            SetSpec(5, 200, .freestyle, sendOff: 210, effort: .moderate, note: "Main set, even pace"),
            SetSpec(4, 50, .freestyle, sendOff: 60, effort: .hard, note: "Build to fast"),
            SetSpec(1, 200, .choice, rest: 0, effort: .easy, note: "Cool-down")
        ]
    )

    static let sprint1500 = Spec(
        name: "Sprint 1500m",
        type: .sprint,
        poolLength: 25,
        notes: "Speed and power. Full recovery between hard efforts.",
        sets: [
            SetSpec(1, 300, .freestyle, rest: 30, effort: .easy, note: "Warm-up"),
            SetSpec(6, 50, .kick, rest: 20, effort: .moderate, note: "Kick with board"),
            SetSpec(8, 50, .freestyle, sendOff: 90, effort: .race, note: "All-out, long rest"),
            SetSpec(4, 25, .butterfly, sendOff: 60, effort: .hard, note: "Sprint fly"),
            SetSpec(1, 200, .choice, rest: 0, effort: .easy, note: "Cool-down")
        ]
    )

    static let technique1200 = Spec(
        name: "Technique 1200m",
        type: .technique,
        poolLength: 25,
        notes: "Focus on form. Slow and deliberate — count your strokes.",
        sets: [
            SetSpec(1, 200, .freestyle, rest: 30, effort: .easy, note: "Warm-up"),
            SetSpec(6, 50, .drill, rest: 25, effort: .easy, note: "Fingertip drag"),
            SetSpec(4, 50, .backstroke, rest: 25, effort: .easy, note: "Rotation focus"),
            SetSpec(4, 50, .breaststroke, rest: 25, effort: .easy, note: "Glide & timing"),
            SetSpec(6, 50, .freestyle, sendOff: 70, effort: .moderate, note: "Low stroke count"),
            SetSpec(1, 100, .choice, rest: 0, effort: .easy, note: "Cool-down")
        ]
    )

    static let mixedIM1800 = Spec(
        name: "Mixed IM 1800m",
        type: .mixed,
        poolLength: 25,
        notes: "All four strokes. Order: fly, back, breast, free.",
        sets: [
            SetSpec(1, 300, .im, rest: 40, effort: .easy, note: "IM warm-up"),
            SetSpec(4, 100, .im, sendOff: 130, effort: .moderate, note: "IM by 25s"),
            SetSpec(4, 75, .butterfly, sendOff: 105, effort: .hard, note: "Fly endurance"),
            SetSpec(4, 75, .backstroke, sendOff: 100, effort: .moderate, note: "Steady back"),
            SetSpec(4, 75, .breaststroke, sendOff: 110, effort: .moderate, note: "Strong pull"),
            SetSpec(1, 200, .freestyle, rest: 0, effort: .easy, note: "Cool-down")
        ]
    )

    /// Build a fresh @Model workout (with ordered sets) from a spec.
    static func makeWorkout(from spec: Spec, isBuiltIn: Bool = true) -> SwimWorkout {
        let workout = SwimWorkout(name: spec.name,
                                  poolLengthMeters: spec.poolLength,
                                  type: spec.type,
                                  notes: spec.notes,
                                  isBuiltIn: isBuiltIn)
        for (index, s) in spec.sets.enumerated() {
            let set = SwimSet(order: index,
                              repeats: s.repeats,
                              distancePerRepMeters: s.distance,
                              stroke: s.stroke,
                              sendOffSeconds: s.sendOff,
                              restSeconds: s.rest,
                              effort: s.effort,
                              note: s.note)
            set.workout = workout
            workout.sets.append(set)
        }
        return workout
    }
}
