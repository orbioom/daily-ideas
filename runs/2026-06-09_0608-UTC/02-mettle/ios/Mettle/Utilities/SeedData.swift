import Foundation
import SwiftData

/// Seeds the built-in challenge programs on first launch. Idempotent: it only
/// inserts when the store has no challenges at all. No day logs are seeded so
/// every empty state is reachable.
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        var descriptor = FetchDescriptor<Challenge>()
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (sortIndex, blueprint) in blueprints.enumerated() {
            let challenge = Challenge(
                name: blueprint.name,
                summary: blueprint.summary,
                durationDays: blueprint.durationDays,
                isBuiltIn: true,
                hardMode: blueprint.hardMode,
                sortIndex: sortIndex
            )
            context.insert(challenge)
            for (order, task) in blueprint.tasks.enumerated() {
                let t = ChallengeTask(
                    title: task.title,
                    detail: task.detail,
                    iconName: task.icon,
                    targetValue: task.target,
                    unit: task.unit,
                    order: order
                )
                t.challenge = challenge
                context.insert(t)
            }
        }
        try? context.save()
    }

    // MARK: - Blueprints

    private struct TaskBlueprint {
        let title: String
        let detail: String
        let icon: String
        let target: Double
        let unit: String
    }

    private struct ChallengeBlueprint {
        let name: String
        let summary: String
        let durationDays: Int
        let hardMode: Bool
        let tasks: [TaskBlueprint]
    }

    private static let blueprints: [ChallengeBlueprint] = [
        ChallengeBlueprint(
            name: "75 Hard",
            summary: "The original mental-toughness program. Miss a single task and you restart at Day 1.",
            durationDays: 75,
            hardMode: true,
            tasks: [
                .init(title: "Workout 1 — 45 min", detail: "Any focused training session.",
                      icon: "figure.run", target: 45, unit: "min"),
                .init(title: "Workout 2 — 45 min (outdoors)", detail: "Second session, must be outside.",
                      icon: "figure.hiking", target: 45, unit: "min"),
                .init(title: "Drink water", detail: "One gallon over the day.",
                      icon: "drop.fill", target: 128, unit: "oz"),
                .init(title: "Follow a diet", detail: "Any plan — no cheat meals, no alcohol.",
                      icon: "fork.knife", target: 0, unit: ""),
                .init(title: "Read 10 pages", detail: "Nonfiction or personal development.",
                      icon: "book.fill", target: 10, unit: "pages"),
                .init(title: "Progress photo", detail: "One photo to mark the day.",
                      icon: "camera.fill", target: 0, unit: "")
            ]
        ),
        ChallengeBlueprint(
            name: "75 Soft",
            summary: "A kinder take on 75 Hard. Missing a day breaks your streak but the run continues.",
            durationDays: 75,
            hardMode: false,
            tasks: [
                .init(title: "Workout — 45 min", detail: "One session a day, rest days allowed in spirit.",
                      icon: "figure.strengthtraining.traditional", target: 45, unit: "min"),
                .init(title: "Drink water", detail: "Stay well hydrated through the day.",
                      icon: "drop.fill", target: 100, unit: "oz"),
                .init(title: "Eat well", detail: "Whole foods, one mindful indulgence allowed.",
                      icon: "leaf.fill", target: 0, unit: ""),
                .init(title: "Read 10 pages", detail: "Any book you enjoy.",
                      icon: "book.fill", target: 10, unit: "pages")
            ]
        ),
        ChallengeBlueprint(
            name: "30-Day Reset",
            summary: "A month to rebuild momentum with simple, sustainable daily habits.",
            durationDays: 30,
            hardMode: false,
            tasks: [
                .init(title: "Move 30 min", detail: "A walk, a workout — anything active.",
                      icon: "figure.walk", target: 30, unit: "min"),
                .init(title: "No late snacks", detail: "Nothing after dinner.",
                      icon: "moon.zzz.fill", target: 0, unit: ""),
                .init(title: "8 glasses water", detail: "Hydrate steadily.",
                      icon: "drop.fill", target: 8, unit: "glasses"),
                .init(title: "Sleep by 11pm", detail: "Lights out, screens away.",
                      icon: "bed.double.fill", target: 0, unit: "")
            ]
        )
    ]
}
