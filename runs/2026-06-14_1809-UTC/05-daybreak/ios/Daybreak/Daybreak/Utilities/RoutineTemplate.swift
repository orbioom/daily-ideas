import Foundation
import SwiftData

/// A pre-filled routine the user can instantiate. The Workout & Evening Reset
/// templates are Pro; the rest are free.
struct RoutineTemplate: Identifiable {
    struct StepSpec {
        let title: String
        let icon: String
        let kind: StepKind
        let seconds: Int
        let note: String
    }

    let id: String
    let name: String
    let timeOfDay: TimeOfDay
    let colorHex: String
    let iconName: String
    let blurb: String
    let isPro: Bool
    let steps: [StepSpec]

    var stepCount: Int { steps.count }

    var estimatedMinutes: Int {
        let secs = steps.reduce(0) { $0 + ($1.kind == .timed ? max(0, $1.seconds) : 0) }
        return max(1, Int((Double(secs) / 60).rounded()))
    }

    /// Build a detached Routine (+ ordered steps) ready to insert.
    func makeRoutine(sortOrder: Int) -> Routine {
        let routine = Routine(name: name,
                              timeOfDay: timeOfDay,
                              colorHex: colorHex,
                              iconName: iconName,
                              sortOrder: sortOrder)
        for (i, spec) in steps.enumerated() {
            let step = RoutineStep(title: spec.title,
                                   iconName: spec.icon,
                                   kind: spec.kind,
                                   durationSec: spec.seconds,
                                   note: spec.note,
                                   sortOrder: i)
            step.routine = routine
            routine.steps.append(step)
        }
        return routine
    }
}

enum RoutineTemplates {
    static let all: [RoutineTemplate] = [
        RoutineTemplate(
            id: "morning-kickstart",
            name: "Morning Kickstart",
            timeOfDay: .morning,
            colorHex: "C77E22",
            iconName: "sunrise.fill",
            blurb: "Wake up the body and set an intention.",
            isPro: false,
            steps: [
                .init(title: "Drink a glass of water", icon: "drop.fill", kind: .checkbox, seconds: 0, note: "Rehydrate first thing."),
                .init(title: "Stretch", icon: "figure.cooldown", kind: .timed, seconds: 120, note: "Gentle full-body stretch."),
                .init(title: "Deep breathing", icon: "wind", kind: .timed, seconds: 60, note: "Slow inhales and exhales."),
                .init(title: "Set today's intention", icon: "target", kind: .checkbox, seconds: 0, note: "One thing that matters most."),
                .init(title: "Make the bed", icon: "bed.double.fill", kind: .checkbox, seconds: 0, note: "")
            ]),
        RoutineTemplate(
            id: "wind-down",
            name: "Wind-Down",
            timeOfDay: .evening,
            colorHex: "9B6BD0",
            iconName: "moon.stars.fill",
            blurb: "Ease the day to a close and prep for sleep.",
            isPro: false,
            steps: [
                .init(title: "Dim the lights", icon: "lightbulb.fill", kind: .checkbox, seconds: 0, note: ""),
                .init(title: "Tidy one surface", icon: "sparkles", kind: .timed, seconds: 120, note: "Clear a desk or counter."),
                .init(title: "Read", icon: "book.fill", kind: .timed, seconds: 300, note: "Something off a screen."),
                .init(title: "Gratitude note", icon: "heart.fill", kind: .checkbox, seconds: 0, note: "One thing you're grateful for."),
                .init(title: "Slow breathing", icon: "wind", kind: .timed, seconds: 90, note: "")
            ]),
        RoutineTemplate(
            id: "deep-work",
            name: "Deep-Work Start",
            timeOfDay: .anytime,
            colorHex: "2E8B7A",
            iconName: "brain.head.profile",
            blurb: "Clear distractions and enter focus.",
            isPro: false,
            steps: [
                .init(title: "Phone on Do Not Disturb", icon: "bell.slash.fill", kind: .checkbox, seconds: 0, note: ""),
                .init(title: "Close extra tabs", icon: "xmark.square.fill", kind: .checkbox, seconds: 0, note: ""),
                .init(title: "Write the one goal", icon: "pencil", kind: .checkbox, seconds: 0, note: "What does done look like?"),
                .init(title: "Box breathing", icon: "wind", kind: .timed, seconds: 60, note: "4 in, 4 hold, 4 out."),
                .init(title: "Start the timer block", icon: "timer", kind: .timed, seconds: 120, note: "Settle in.")
            ]),
        RoutineTemplate(
            id: "workout-warmup",
            name: "Workout Warm-up",
            timeOfDay: .anytime,
            colorHex: "C0492F",
            iconName: "figure.run",
            blurb: "Prime your muscles before training.",
            isPro: true,
            steps: [
                .init(title: "Light cardio", icon: "figure.walk", kind: .timed, seconds: 120, note: "Jog in place or march."),
                .init(title: "Arm circles", icon: "figure.arms.open", kind: .timed, seconds: 45, note: ""),
                .init(title: "Leg swings", icon: "figure.flexibility", kind: .timed, seconds: 45, note: ""),
                .init(title: "Hip openers", icon: "figure.cooldown", kind: .timed, seconds: 60, note: ""),
                .init(title: "Activation set", icon: "bolt.fill", kind: .checkbox, seconds: 0, note: "A few easy reps.")
            ]),
        RoutineTemplate(
            id: "evening-reset",
            name: "Evening Reset",
            timeOfDay: .evening,
            colorHex: "5E72C8",
            iconName: "house.fill",
            blurb: "Reset the home and your mind for tomorrow.",
            isPro: true,
            steps: [
                .init(title: "10-minute tidy", icon: "sparkles", kind: .timed, seconds: 600, note: "Reset shared spaces."),
                .init(title: "Lay out tomorrow's clothes", icon: "tshirt.fill", kind: .checkbox, seconds: 0, note: ""),
                .init(title: "Plan tomorrow's top 3", icon: "list.number", kind: .checkbox, seconds: 0, note: ""),
                .init(title: "Prep water bottle", icon: "drop.fill", kind: .checkbox, seconds: 0, note: ""),
                .init(title: "Quiet reflection", icon: "moon.fill", kind: .timed, seconds: 120, note: "")
            ])
    ]
}
