import Foundation
import SwiftData

/// Seeds the stretch catalog and a few built-in routines on first launch.
enum SeedData {

    struct Seed {
        let name: String
        let area: BodyArea
        let detail: String
        let seconds: Int
        let bothSides: Bool
        let difficulty: Int
    }

    static let catalog: [Seed] = [
        .init(name: "Neck rolls", area: .neck, detail: "Drop your chin and roll slowly ear to ear. Keep shoulders soft.", seconds: 30, bothSides: false, difficulty: 1),
        .init(name: "Side neck stretch", area: .neck, detail: "Gently tilt your head toward one shoulder, hand resting on the crown.", seconds: 25, bothSides: true, difficulty: 1),
        .init(name: "Shoulder rolls", area: .shoulders, detail: "Roll shoulders up, back, and down in slow circles.", seconds: 30, bothSides: false, difficulty: 1),
        .init(name: "Cross-body shoulder", area: .shoulders, detail: "Draw one arm across your chest, supporting it with the other.", seconds: 30, bothSides: true, difficulty: 1),
        .init(name: "Doorway chest opener", area: .chest, detail: "Forearms on a frame, step through until you feel a gentle chest stretch.", seconds: 30, bothSides: false, difficulty: 2),
        .init(name: "Thread the needle", area: .upperBack, detail: "From all fours, reach one arm under the other and rest on the floor.", seconds: 30, bothSides: true, difficulty: 2),
        .init(name: "Cat–cow", area: .upperBack, detail: "Alternate arching and rounding your spine with your breath.", seconds: 40, bothSides: false, difficulty: 1),
        .init(name: "Child's pose", area: .lowerBack, detail: "Sit hips to heels, arms long, forehead resting down.", seconds: 45, bothSides: false, difficulty: 1),
        .init(name: "Supine twist", area: .lowerBack, detail: "Lie back, drop both knees to one side, gaze the other way.", seconds: 30, bothSides: true, difficulty: 1),
        .init(name: "Cobra", area: .lowerBack, detail: "Lie face down, press through the hands to lift the chest gently.", seconds: 25, bothSides: false, difficulty: 2),
        .init(name: "Figure-four", area: .glutes, detail: "Cross one ankle over the opposite knee and draw the leg toward you.", seconds: 35, bothSides: true, difficulty: 2),
        .init(name: "Pigeon pose", area: .hips, detail: "Front shin across the mat, back leg long; fold forward to taste.", seconds: 45, bothSides: true, difficulty: 3),
        .init(name: "Low lunge", area: .hips, detail: "Sink the hips forward in a lunge, back knee down, chest tall.", seconds: 35, bothSides: true, difficulty: 2),
        .init(name: "Butterfly", area: .hips, detail: "Soles together, let the knees fall open; hinge gently forward.", seconds: 40, bothSides: false, difficulty: 1),
        .init(name: "Standing hamstring", area: .hamstrings, detail: "Hinge at the hips over a long front leg, back flat.", seconds: 30, bothSides: true, difficulty: 2),
        .init(name: "Seated forward fold", area: .hamstrings, detail: "Legs long, fold from the hips reaching toward the feet.", seconds: 40, bothSides: false, difficulty: 2),
        .init(name: "Standing quad", area: .quads, detail: "Hold one ankle behind you, knees together, hips forward.", seconds: 30, bothSides: true, difficulty: 1),
        .init(name: "Couch stretch", area: .quads, detail: "Back foot up against a wall, sink into a tall kneeling lunge.", seconds: 40, bothSides: true, difficulty: 3),
        .init(name: "Wall calf stretch", area: .calves, detail: "Press a straight back leg's heel down against a wall.", seconds: 30, bothSides: true, difficulty: 1),
        .init(name: "Downward dog", area: .calves, detail: "Hips high, pedal the heels to wake up calves and hamstrings.", seconds: 35, bothSides: false, difficulty: 2),
        .init(name: "Ankle circles", area: .ankles, detail: "Lift one foot and trace slow circles in both directions.", seconds: 25, bothSides: true, difficulty: 1),
        .init(name: "Wrist flexor stretch", area: .wrists, detail: "Arm straight, palm up, gently draw the fingers back.", seconds: 25, bothSides: true, difficulty: 1),
        .init(name: "World's greatest stretch", area: .fullBody, detail: "Lunge, reach the inside elbow down, then rotate the top arm to the sky.", seconds: 30, bothSides: true, difficulty: 3),
        .init(name: "Standing side bend", area: .fullBody, detail: "Reach one arm overhead and lean away to lengthen the side body.", seconds: 25, bothSides: true, difficulty: 1),
        .init(name: "Forward fold hang", area: .fullBody, detail: "Hinge forward, let the head and arms hang heavy; soft knees.", seconds: 40, bothSides: false, difficulty: 1)
    ]

    struct RoutineSeed {
        let name: String
        let summary: String
        let stretches: [String]
        let seconds: [Int]
    }

    static let routines: [RoutineSeed] = [
        .init(name: "Morning Wake-Up",
              summary: "A gentle full-body flow to start the day.",
              stretches: ["Cat–cow", "Child's pose", "Standing side bend", "Forward fold hang", "Standing quad", "Shoulder rolls"],
              seconds: [40, 45, 25, 40, 30, 30]),
        .init(name: "Desk Reset",
              summary: "Undo a long sitting session in five minutes.",
              stretches: ["Neck rolls", "Side neck stretch", "Cross-body shoulder", "Doorway chest opener", "Thread the needle", "Wrist flexor stretch"],
              seconds: [30, 25, 30, 30, 30, 25]),
        .init(name: "Hips & Lower Back",
              summary: "Release tension where most of us hold it.",
              stretches: ["Low lunge", "Figure-four", "Pigeon pose", "Supine twist", "Child's pose", "Butterfly"],
              seconds: [35, 35, 45, 30, 45, 40]),
        .init(name: "Post-Run Cooldown",
              summary: "Lengthen the big movers after a session.",
              stretches: ["Standing hamstring", "Standing quad", "Wall calf stretch", "Figure-four", "Couch stretch", "Forward fold hang"],
              seconds: [30, 30, 30, 35, 40, 40])
    ]

    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Stretch>())) ?? []
        guard existing.isEmpty else { return }

        var byName: [String: Stretch] = [:]
        for s in catalog {
            let stretch = Stretch(name: s.name, area: s.area, detail: s.detail,
                                  defaultSeconds: s.seconds, bothSides: s.bothSides,
                                  difficulty: s.difficulty)
            context.insert(stretch)
            byName[s.name] = stretch
        }
        for r in routines {
            let routine = Routine(name: r.name, summary: r.summary, isBuiltIn: true)
            context.insert(routine)
            for (i, name) in r.stretches.enumerated() {
                guard let stretch = byName[name] else { continue }
                let secs = i < r.seconds.count ? r.seconds[i] : stretch.defaultSeconds
                let step = RoutineStep(order: i, seconds: secs, stretch: stretch)
                step.routine = routine
                context.insert(step)
            }
        }
        try? context.save()
    }
}
