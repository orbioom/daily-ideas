import Foundation
import SwiftData

/// One-time seeding of triggers, coping items, reassurance cards, and a small
/// history of past episodes so insights feel alive on first launch.
enum SeedData {

    // MARK: - Public entry

    /// Seeds the store if it appears empty. Safe to call on every launch.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let triggerCount = (try? context.fetchCount(FetchDescriptor<Trigger>())) ?? 0
        if triggerCount == 0 {
            seedTriggers(context)
        }

        let copingCount = (try? context.fetchCount(FetchDescriptor<CopingItem>())) ?? 0
        if copingCount == 0 {
            seedCoping(context)
        }

        let reassuranceCount = (try? context.fetchCount(FetchDescriptor<ReassuranceCard>())) ?? 0
        if reassuranceCount == 0 {
            seedReassurance(context)
        }

        let episodeCount = (try? context.fetchCount(FetchDescriptor<PanicEpisode>())) ?? 0
        if episodeCount == 0 {
            seedEpisodes(context)
        }

        try? context.save()
    }

    // MARK: - Triggers (~12)

    static let triggerNames: [String] = [
        "Caffeine", "Poor sleep", "Conflict", "Crowds", "Work stress",
        "Health worry", "Money", "Driving", "Social event", "News",
        "Alcohol", "Unknown"
    ]

    @MainActor
    private static func seedTriggers(_ context: ModelContext) {
        for name in triggerNames {
            context.insert(Trigger(name: name, isCustom: false))
        }
    }

    // MARK: - Coping items (~16)

    @MainActor
    private static func seedCoping(_ context: ModelContext) {
        let items: [(String, String, CopingKind)] = [
            ("This feeling will pass", "Panic peaks and fades. It always comes back down — usually within minutes.", .statement),
            ("I am safe right now", "My body is reacting, but I am not in danger. This is a false alarm, not a real one.", .statement),
            ("Both feet on the floor", "Press your feet down and name them. Feel the ground holding you.", .action),
            ("Splash cold water", "Cold water on your face or wrists can calm the nervous system quickly.", .action),
            ("Breathe out longer", "A slow, long exhale tells your body it's okay to settle.", .action),
            ("Name five things you see", "Look around slowly and quietly name five things. Bring yourself here.", .action),
            ("Call someone safe", "You don't have to do this alone. Reaching out is strength, not weakness.", .contact),
            ("This is a wave, not a wall", "It feels huge, but it's temporary. Let it rise and fall.", .statement),
            ("Unclench your jaw", "Soften your jaw, drop your shoulders, let your hands rest open.", .action),
            ("Hold something cold", "Grip an ice cube or a cold can. The sensation pulls you to the present.", .action),
            ("I've survived this before", "Every hard moment so far has ended. This one will too.", .statement),
            ("Slow, gentle counting", "Count slowly to ten, then back down. Give your mind a quiet task.", .action),
            ("Put a hand on your heart", "Feel it beating. Offer yourself a little warmth and patience.", .action),
            ("It's okay to feel this", "Fighting the feeling can feed it. Let it be here, and let it move through.", .statement),
            ("Step outside for air", "If you can, find some fresh air and open sky.", .action),
            ("You are doing your best", "Just getting through this moment is enough. Be gentle with yourself.", .statement)
        ]
        for (i, item) in items.enumerated() {
            context.insert(CopingItem(
                title: item.0, detail: item.1, kind: item.2,
                isCustom: false, sortOrder: i, isFavorite: i < 3
            ))
        }
    }

    // MARK: - Reassurance cards (~20)

    @MainActor
    private static func seedReassurance(_ context: ModelContext) {
        let lines = [
            "You are safe. This will pass.",
            "Your body is trying to protect you. There is no real danger here.",
            "Breathe slowly. You have time.",
            "This is hard, and you are handling it.",
            "Nothing about this moment is permanent.",
            "You don't have to fight it. Just let it move through.",
            "Every wave of panic has crested and fallen. So will this one.",
            "You are not alone, even when it feels that way.",
            "Your feelings are real, and they are also temporary.",
            "You have gotten through every hard moment so far.",
            "It's okay to slow down. It's okay to rest.",
            "You are allowed to take up space and to take your time.",
            "This is your nervous system, not your future.",
            "Be as kind to yourself as you would be to a friend.",
            "One slow breath at a time is enough.",
            "You are still here. You are still okay.",
            "The calm always comes back. Wait gently for it.",
            "You are stronger than this moment feels.",
            "Let your shoulders drop. Let your breath soften.",
            "Whatever you're feeling, you don't have to feel it forever."
        ]
        for line in lines {
            context.insert(ReassuranceCard(text: line, isCustom: false))
        }
    }

    // MARK: - Past episodes (~14 over ~8 weeks)

    @MainActor
    private static func seedEpisodes(_ context: ModelContext) {
        // Build a lookup of seeded triggers to attach.
        let triggers = (try? context.fetch(FetchDescriptor<Trigger>())) ?? []
        func trigger(_ name: String) -> Trigger? {
            triggers.first { $0.name == name }
        }

        let cal = Calendar.current
        let now = Date.now

        // (daysAgo, hour, before, after, durMin, context, [triggers], [helpedBy], note)
        let plan: [(Int, Int, Int, Int?, Int?, EpisodeContext, [String], [String], String)] = [
            (54, 22, 9, 4, 18, .homeAlone, ["Poor sleep", "Health worry"], ["This feeling will pass", "Breathe out longer"], "Woke up with my heart racing."),
            (50, 14, 7, 3, 10, .work, ["Work stress", "Caffeine"], ["Both feet on the floor"], "Right before a meeting."),
            (46, 19, 8, 5, 15, .publicPlace, ["Crowds"], ["Name five things you see"], "Busy supermarket."),
            (41, 8, 6, 2, 8, .transit, ["Driving"], ["Breathe out longer", "Slow, gentle counting"], "Stuck in traffic."),
            (37, 23, 8, 3, 20, .homeAlone, ["Poor sleep", "Unknown"], ["Call someone safe"], "Late night spiral."),
            (33, 16, 5, 2, 6, .work, ["Work stress"], ["Both feet on the floor"], ""),
            (28, 20, 7, 4, 12, .home, ["Conflict"], ["Put a hand on your heart"], "After an argument."),
            (24, 11, 6, 3, 9, .publicPlace, ["Social event"], ["This is a wave, not a wall"], "Party felt overwhelming."),
            (19, 21, 8, 4, 16, .homeAlone, ["Health worry", "News"], ["This feeling will pass", "Splash cold water"], ""),
            (15, 9, 5, 1, 5, .work, ["Caffeine", "Work stress"], ["Breathe out longer"], "Caught it early."),
            (11, 18, 6, 3, 8, .transit, ["Crowds", "Driving"], ["Slow, gentle counting"], "On the train home."),
            (7, 22, 7, 2, 11, .homeAlone, ["Poor sleep"], ["Call someone safe", "Hold something cold"], "Reached out to a friend."),
            (4, 13, 4, 1, 4, .home, ["Money"], ["I've survived this before"], "Felt it pass quickly."),
            (1, 20, 5, 2, 6, .home, ["Unknown"], ["Breathe out longer", "This feeling will pass"], "Used the breathing tool.")
        ]

        for entry in plan {
            let base = cal.date(byAdding: .day, value: -entry.0, to: now) ?? now
            let started = cal.date(bySettingHour: entry.1, minute: 0, second: 0, of: base) ?? base
            let attached = entry.6.compactMap { trigger($0) }
            let ep = PanicEpisode(
                startedAt: started,
                durationMinutes: entry.4,
                intensityBefore: entry.2,
                intensityAfter: entry.3,
                context: entry.5.rawValue,
                note: entry.8,
                triggers: attached,
                helpedBy: entry.7
            )
            context.insert(ep)
        }
    }
}
