import Foundation
import SwiftData

/// Seeds a small, realistic set of entries so the timeline, calendar, and
/// insights feel alive on first run. Optional — gated behind onboarding choice.
enum SeedData {

    @MainActor
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        let work = Tag(name: "work", colorHex: 0x6E7BA6)
        let home = Tag(name: "home", colorHex: 0x7CA68F)
        let ideas = Tag(name: "ideas", colorHex: 0xB0814E)
        let people = Tag(name: "people", colorHex: 0x9E5E7E)
        [work, home, ideas, people].forEach { context.insert($0) }

        struct Seed {
            let dayOffset: Int
            let title: String
            let body: String
            let mood: Int
            let tags: [Tag]
            let prompt: String
        }

        let seeds: [Seed] = [
            Seed(dayOffset: 0, title: "A quieter morning",
                 body: "Woke before the alarm and let the room stay dark for a while. There's a kind of permission in the early hour — nothing is owed yet. Made coffee slowly and watched the light come up over the rooftops.",
                 mood: 4, tags: [home],
                 prompt: "Describe the light in the room right now."),
            Seed(dayOffset: 1, title: "Shipped the thing",
                 body: "Long day but we got the release out. Strange relief — the kind that arrives quietly instead of all at once. Grateful for the team carrying the last mile.",
                 mood: 5, tags: [work, people], prompt: ""),
            Seed(dayOffset: 2, title: "",
                 body: "Tired and a little flat. Didn't sleep well. Trying not to make it mean anything more than it is.",
                 mood: 2, tags: [], prompt: "How did your energy move through the day?"),
            Seed(dayOffset: 4, title: "Walk by the canal",
                 body: "Took the long way home along the water. An idea I'd been circling for weeks finally clicked while I wasn't trying. Wrote it down on my phone before it slipped.",
                 mood: 4, tags: [ideas], prompt: ""),
            Seed(dayOffset: 6, title: "Dinner with Sam",
                 body: "We talked for three hours and it felt like twenty minutes. Funny how the right company resets something. Left lighter than I arrived.",
                 mood: 5, tags: [people], prompt: "Describe a conversation that stayed with you."),
            Seed(dayOffset: 9, title: "Slow Sunday",
                 body: "Cleaned the kitchen, read on the couch, didn't look at a screen until noon. A good reminder that rest is allowed to be unremarkable.",
                 mood: 3, tags: [home], prompt: ""),
            Seed(dayOffset: 13, title: "First frost",
                 body: "The grass was white this morning. Stood at the window with tea longer than I meant to. Small seasons turning.",
                 mood: 4, tags: [home], prompt: ""),
        ]

        for s in seeds {
            guard let day = cal.date(byAdding: .day, value: -s.dayOffset, to: today) else { continue }
            // Spread entries to mid-morning so they read naturally.
            let when = cal.date(bySettingHour: 8, minute: 30, second: 0, of: day) ?? day
            let entry = JournalEntry(
                date: when, title: s.title, body: s.body,
                mood: s.mood, promptText: s.prompt,
                createdAt: when, modifiedAt: when
            )
            entry.tags = s.tags
            context.insert(entry)
        }

        try? context.save()
    }
}
