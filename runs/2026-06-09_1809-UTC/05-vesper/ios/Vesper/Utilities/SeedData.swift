import Foundation
import SwiftData

/// Seeds a calm, realistic set of prayers and reading logs on first launch so
/// charts, streaks, and rankings are never empty for a brand-new user. Guarded
/// so it runs at most once. Dates are computed relative to "now" at seed time.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Prayer>())) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: .now) ?? .now
        }

        // MARK: Prayers
        // (title, body, category, status, person, pinned, createdAgo, answeredAgo, answeredNote,
        //  updates: [(daysAgo, text)])
        struct Spec {
            let title: String
            let body: String
            let category: PrayerCategory
            let status: PrayerStatus
            let person: String
            let pinned: Bool
            let createdAgo: Int
            let answeredAgo: Int?
            let answeredNote: String
            let updates: [(Int, String)]
        }

        let specs: [Spec] = [
            Spec(title: "Grandmother's recovery", body: "Holding Nana through her hip surgery and the long rehab ahead.",
                 category: .intercession, status: .praying, person: "Nana", pinned: true,
                 createdAgo: 41, answeredAgo: nil, answeredNote: "",
                 updates: [(34, "Surgery went well — grateful."), (12, "She's walking a few steps now. Slow but steady.")]),
            Spec(title: "Clarity on the job offer", body: "Two paths, both good. Asking for wisdom to choose well, not just safely.",
                 category: .guidance, status: .praying, person: "", pinned: true,
                 createdAgo: 23, answeredAgo: nil, answeredNote: "",
                 updates: [(18, "Made a list of what matters most."), (4, "Leaning one way but want to sit with it longer.")]),
            Spec(title: "Thank you for the rains", body: "After a long dry spell, the garden finally drank deep.",
                 category: .gratitude, status: .answered, person: "", pinned: false,
                 createdAgo: 30, answeredAgo: 26, answeredNote: "Three days of gentle rain. The whole valley turned green.",
                 updates: [(28, "Clouds gathering at last.")]),
            Spec(title: "Peace for Marcus", body: "He's anxious about the move. Asking for a settled heart for him.",
                 category: .intercession, status: .praying, person: "Marcus", pinned: false,
                 createdAgo: 19, answeredAgo: nil, answeredNote: "",
                 updates: [(9, "He sounded lighter on the phone tonight.")]),
            Spec(title: "Forgiveness toward Dad", body: "Old wounds resurfacing. I want to let this go, gently and for real.",
                 category: .confession, status: .praying, person: "Dad", pinned: false,
                 createdAgo: 52, answeredAgo: nil, answeredNote: "",
                 updates: [(40, "Wrote a letter I haven't sent."), (15, "We talked. It wasn't perfect but it was honest.")]),
            Spec(title: "Strength for the night shifts", body: "The long weeks are wearing on me. Asking to be carried through.",
                 category: .petition, status: .answered, person: "", pinned: false,
                 createdAgo: 60, answeredAgo: 33, answeredNote: "Schedule eased up. I feel like myself again.",
                 updates: [(50, "Exhausted but holding on."), (38, "A coworker offered to swap shifts — small mercy.")]),
            Spec(title: "Sarah's interview", body: "She's worked so hard. Asking for calm nerves and the right fit.",
                 category: .intercession, status: .answered, person: "Sarah", pinned: false,
                 createdAgo: 22, answeredAgo: 11, answeredNote: "She got the role. Tears of joy on the call.",
                 updates: [(20, "Interview is Thursday."), (12, "It went well, now we wait.")]),
            Spec(title: "Praise for a mended friendship", body: "What felt broken is being knit back together.",
                 category: .praise, status: .answered, person: "Tomas", pinned: false,
                 createdAgo: 45, answeredAgo: 40, answeredNote: "We shared a long, easy meal. Grace did this, not me.",
                 updates: []),
            Spec(title: "Patience with the waiting", body: "The results are taking longer than I'd like. Help me wait without unraveling.",
                 category: .petition, status: .praying, person: "", pinned: false,
                 createdAgo: 16, answeredAgo: nil, answeredNote: "",
                 updates: [(8, "Still nothing. Trying to breathe.")]),
            Spec(title: "For Elena's little one", body: "A scary diagnosis for such a small child. Lifting the whole family.",
                 category: .intercession, status: .praying, person: "Elena", pinned: false,
                 createdAgo: 27, answeredAgo: nil, answeredNote: "",
                 updates: [(21, "Specialist appointment set."), (6, "Good news on the latest scan. Cautiously hopeful.")]),
            Spec(title: "Gratitude for steady work", body: "After the uncertain spring, there is bread on the table.",
                 category: .gratitude, status: .praying, person: "", pinned: false,
                 createdAgo: 14, answeredAgo: nil, answeredNote: "", updates: []),
            Spec(title: "Confession of impatience", body: "I snapped at the kids again. Asking for a softer, slower heart.",
                 category: .confession, status: .praying, person: "", pinned: false,
                 createdAgo: 9, answeredAgo: nil, answeredNote: "",
                 updates: [(3, "A better day today. Apologized and we hugged it out.")]),
            Spec(title: "Wisdom for the budget", body: "Tight months ahead. Asking for clear eyes and a generous spirit.",
                 category: .guidance, status: .praying, person: "", pinned: false,
                 createdAgo: 11, answeredAgo: nil, answeredNote: "", updates: []),
            Spec(title: "Healing for Aunt Rose", body: "The treatments are hard on her. Asking for comfort and rest.",
                 category: .intercession, status: .praying, person: "Aunt Rose", pinned: false,
                 createdAgo: 38, answeredAgo: nil, answeredNote: "",
                 updates: [(30, "Round two done."), (10, "Tired but in good spirits when I visited.")]),
            Spec(title: "Thank you for safe travels", body: "The whole family home again, no harm on the long road.",
                 category: .gratitude, status: .answered, person: "", pinned: false,
                 createdAgo: 18, answeredAgo: 15, answeredNote: "Everyone back, hugs all around.",
                 updates: []),
            Spec(title: "Courage to apologize", body: "I know I was wrong. Asking for the humility to say so first.",
                 category: .confession, status: .answered, person: "Priya", pinned: false,
                 createdAgo: 13, answeredAgo: 7, answeredNote: "I said sorry. She was kinder than I deserved.",
                 updates: [(10, "Still rehearsing the words.")]),
            Spec(title: "Hope for the neighborhood", body: "So much hardship on our street lately. Asking for light to break in.",
                 category: .petition, status: .praying, person: "", pinned: false,
                 createdAgo: 49, answeredAgo: nil, answeredNote: "",
                 updates: [(20, "A few neighbors started a meal share.")]),
            Spec(title: "Praise after the storm", body: "The roof held, the family is safe. Giving thanks.",
                 category: .praise, status: .answered, person: "", pinned: false,
                 createdAgo: 35, answeredAgo: 34, answeredNote: "Power back, no one hurt. Deeply grateful.",
                 updates: []),
            Spec(title: "For my own restless mind", body: "Sleep won't come easy. Asking for quiet at the end of the day.",
                 category: .petition, status: .praying, person: "", pinned: false,
                 createdAgo: 6, answeredAgo: nil, answeredNote: "", updates: []),
            Spec(title: "Guidance for the new role", body: "Stepping into leadership I don't feel ready for. Asking for steady footing.",
                 category: .guidance, status: .praying, person: "", pinned: false,
                 createdAgo: 31, answeredAgo: nil, answeredNote: "",
                 updates: [(25, "First week done. Survived."), (5, "Found a mentor. Things feel less heavy.")]),
            Spec(title: "Thanksgiving for a friend's call", body: "Right when I needed it, the phone rang.",
                 category: .gratitude, status: .answered, person: "Dani", pinned: false,
                 createdAgo: 8, answeredAgo: 8, answeredNote: "We talked for an hour. I feel less alone.",
                 updates: []),
            Spec(title: "For the church food pantry", body: "Shelves running low as needs grow. Asking for provision.",
                 category: .intercession, status: .archived, person: "", pinned: false,
                 createdAgo: 70, answeredAgo: nil, answeredNote: "",
                 updates: [(60, "A large donation came through. Setting this to rest with thanks.")]),
            Spec(title: "An old worry, finally laid down", body: "Carried this fear for years. Ready to release it.",
                 category: .petition, status: .archived, person: "", pinned: false,
                 createdAgo: 90, answeredAgo: nil, answeredNote: "",
                 updates: [(80, "It simply doesn't grip me the way it used to.")]),
            Spec(title: "Praise for a quiet ordinary day", body: "Nothing dramatic. Just goodness, and I noticed it.",
                 category: .praise, status: .praying, person: "", pinned: false,
                 createdAgo: 2, answeredAgo: nil, answeredNote: "", updates: []),
            Spec(title: "For Jonah's first day of school", body: "My little one, big world. Asking for friends and courage for him.",
                 category: .intercession, status: .praying, person: "Jonah", pinned: false,
                 createdAgo: 4, answeredAgo: nil, answeredNote: "", updates: []),
        ]

        for s in specs {
            let prayer = Prayer(
                title: s.title,
                body: s.body,
                category: s.category,
                status: s.status,
                personName: s.person,
                isPinned: s.pinned,
                createdAt: daysAgo(s.createdAgo),
                answeredAt: s.answeredAgo.map { daysAgo($0) },
                answeredNote: s.answeredNote
            )
            context.insert(prayer)
            for (ago, text) in s.updates {
                let update = PrayerUpdate(date: daysAgo(ago), text: text, prayer: prayer)
                context.insert(update)
            }
        }

        // MARK: Reading logs across recent days
        let library = DevotionLibrary.all
        // (daysAgo, devotionIndex, note)
        let logSpec: [(Int, Int, String)] = [
            (0, 1, "Needed this stillness this morning."),
            (1, 8, ""),
            (1, 20, "A future held in goodwill — that helped."),
            (2, 3, ""),
            (3, 11, "Set down a burden I didn't know I was carrying."),
            (4, 16, ""),
            (5, 2, "Be still. Trying to."),
            (6, 24, "Read it like it was spoken to me."),
            (7, 5, ""),
            (8, 14, ""),
            (9, 33, "Cast it on him. Again."),
            (11, 9, ""),
            (12, 28, "Which fruit is ripening? Patience, maybe."),
            (14, 0, ""),
            (16, 19, "Rest and waiting, together."),
            (18, 6, ""),
            (20, 12, "Courage, with company."),
            (23, 31, "Grace meets me in the weak place."),
            (26, 4, ""),
            (30, 29, "A long night, but morning is promised."),
        ]
        for (ago, idx, note) in logSpec where library.indices.contains(idx) {
            let log = ReadingLog(date: daysAgo(ago), devotionID: library[idx].id, note: note)
            context.insert(log)
        }

        try? context.save()
    }
}
