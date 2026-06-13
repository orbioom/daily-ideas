import Foundation
import SwiftData

enum SeedData {
    /// Populate a fresh store with a small, interlinked set of notes so the
    /// app never opens empty for a first-time user exploring the demo.
    static func populate(_ context: ModelContext) {
        let inbox = Folder(name: "Inbox", symbol: "tray", colorIndex: 1, sortOrder: 0)
        let ideas = Folder(name: "Ideas", symbol: "lightbulb", colorIndex: 3, sortOrder: 1)
        let journal = Folder(name: "Journal", symbol: "book.closed", colorIndex: 4, sortOrder: 2)
        let work = Folder(name: "Work", symbol: "briefcase", colorIndex: 2, sortOrder: 3)
        [inbox, ideas, journal, work].forEach { context.insert($0) }

        let tWriting = Tag(name: "writing")
        let tProduct = Tag(name: "product")
        let tHealth = Tag(name: "health")
        let tQuotes = Tag(name: "quotes")
        [tWriting, tProduct, tHealth, tQuotes].forEach { context.insert($0) }

        func note(_ title: String, _ body: String, folder: Folder, color: Int = 0,
                  pinned: Bool = false, tags: [Tag] = [], daysAgo: Int = 0) {
            let n = Note(title: title, body: body, folder: folder)
            n.colorIndex = color
            n.isPinned = pinned
            n.tags = tags
            n.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            n.updatedAt = n.createdAt
            context.insert(n)
        }

        note("Welcome to Verso",
             """
             Verso is a calm place to **think in writing** — Markdown notes with
             folders, tags, and links between ideas. No subscription to read your
             own words.

             ## A few things to try
             - Write in Markdown — *italics*, **bold**, `code`, lists
             - Link notes with double brackets: [[Markdown cheat sheet]]
             - Tag and file notes, then find them with search

             > The palest ink is better than the best memory.
             """,
             folder: inbox, color: 1, pinned: true, tags: [tWriting])

        note("Markdown cheat sheet",
             """
             # Headings use #
             ## Smaller heading

             **Bold**, *italic*, ~~strike~~, and `inline code`.

             - Bullet list
             - Another item

             1. Numbered list
             2. Second item

             - [ ] An open task
             - [x] A finished task

             > Block quotes start with a greater-than sign.

             Link to other notes with [[Welcome to Verso]].
             """,
             folder: inbox, tags: [tWriting])

        note("Product principles",
             """
             What makes a tool feel trustworthy?

             1. It respects your attention
             2. It never holds your data hostage
             3. It is fast and quiet

             Related: [[The cost of subscriptions]] and [[Welcome to Verso]].
             """,
             folder: work, color: 2, pinned: true, tags: [tProduct], daysAgo: 1)

        note("The cost of subscriptions",
             """
             Most note apps now charge monthly just to **sync your own text**.
             The opening for Verso is honest pricing: a one-time unlock, local
             first, your notes are files you control.

             See also [[Product principles]].
             """,
             folder: ideas, color: 3, tags: [tProduct], daysAgo: 2)

        note("Morning pages",
             """
             Three pages, longhand, first thing. The point isn't the writing —
             it's clearing the runway. Today felt lighter after.

             #journal
             """,
             folder: journal, color: 4, tags: [tWriting], daysAgo: 1)

        note("Sleep experiment",
             """
             Week 1 of a consistent **wind-down** routine.

             - [x] No screens after 22:30
             - [x] Magnesium
             - [ ] Cold room
             - [ ] Read fiction, not feeds

             Energy is up. Keep going.
             """,
             folder: journal, tags: [tHealth], daysAgo: 3)

        note("Quotes worth keeping",
             """
             > We are what we repeatedly do. Excellence, then, is not an act, but a habit.

             > The secret of getting ahead is getting started.

             > A year from now you may wish you had started today.
             """,
             folder: ideas, color: 5, tags: [tQuotes], daysAgo: 4)

        note("Reading list",
             """
             ## To read
             1. *Bird by Bird* — Anne Lamott
             2. *Several Short Sentences About Writing*
             3. *The Elements of Style*

             ## Reading now
             - *Deep Work*

             A good companion to [[Morning pages]].
             """,
             folder: ideas, tags: [tWriting, tQuotes], daysAgo: 5)

        note("Standup notes",
             """
             **Yesterday:** finished the editor.
             **Today:** backlinks + search.
             **Blockers:** none.
             """,
             folder: work, tags: [tProduct], daysAgo: 1)

        note("Grocery + meals",
             """
             - [ ] Oats
             - [ ] Spinach
             - [ ] Greek yogurt
             - [ ] Lentils
             - [ ] Olive oil
             """,
             folder: inbox, daysAgo: 0)

        note("Trip idea: Lisbon",
             """
             Late September. Cooler, fewer crowds.

             - Alfama at golden hour
             - Day trip to Sintra
             - Pastéis de Belém

             Budget thoughts in [[Product principles]]? No — wrong note. Just dreaming.
             """,
             folder: ideas, color: 2, tags: [], daysAgo: 6)

        note("Gratitude",
             """
             Three small things today:
             1. Coffee on the balcony
             2. A long walk with no phone
             3. Finishing a hard task

             #journal
             """,
             folder: journal, color: 4, tags: [tHealth], daysAgo: 2)

        try? context.save()
    }
}
