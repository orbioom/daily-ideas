import Foundation
import SwiftData

/// Seeds realistic sample data on first launch only. Guarded by a count check
/// AND an @AppStorage flag so it never double-seeds.
@MainActor
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        let flagKey = "didSeed_v1"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        // Belt-and-braces: don't seed if any board already exists.
        let existing = try? context.fetch(FetchDescriptor<Board>())
        if let existing, !existing.isEmpty {
            UserDefaults.standard.set(true, forKey: flagKey)
            return
        }

        buildSampleData(context: context)

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
        } catch {
            // If saving fails we leave the flag unset so it retries next launch.
            // The in-memory graph still works for this session.
        }
    }

    // MARK: - Sample graph

    private static func buildSampleData(context: ModelContext) {
        let now = Date()

        // Shared labels.
        let labelSpecs: [(String, Int)] = [
            ("Bug", 0xD23B3B), ("Feature", 0x2D7FF9), ("Design", 0xE0529C),
            ("Urgent", 0xF0663B), ("Research", 0x6B5BFF), ("Marketing", 0x18A957)
        ]
        var labels: [Label] = []
        for spec in labelSpecs {
            let l = Label(name: spec.0, colorHex: spec.1)
            context.insert(l)
            labels.append(l)
        }
        func label(_ name: String) -> Label? { labels.first { $0.name == name } }

        // 1) Product Launch — Kanban.
        let product = BoardFactory.makeBoard(
            name: "Product Launch", colorHex: 0x2D7FF9, symbolName: "rocket.fill",
            template: .kanban, sortIndex: 0, isPro: true, context: context
        )
        seedCards(into: product, context: context, now: now, plans: [
            ("Backlog", [
                ("Competitive teardown", .medium, 6, ["Research"], ["Pull 5 rivals", "Note pricing", "Summarize gaps"], 1),
                ("Pricing model v2", .low, nil, ["Marketing"], [], 0),
                ("Localization scope", .low, 14, [], [], 0)
            ]),
            ("Ready", [
                ("Onboarding redesign", .high, 3, ["Design", "Feature"], ["Wireframes", "Copy pass", "Dev handoff"], 1),
                ("Crash on launch (iPad)", .high, -1, ["Bug", "Urgent"], ["Reproduce", "Patch", "Verify"], 0)
            ]),
            ("In Progress", [
                ("Paywall A/B test", .high, 1, ["Feature"], ["Variant A", "Variant B", "Metrics"], 2),
                ("Empty-state polish", .medium, 2, ["Design"], [], 0)
            ]),
            ("Review", [
                ("App Store screenshots", .medium, 0, ["Marketing", "Design"], ["6.7\"", "6.1\"", "iPad"], 2)
            ]),
            ("Done", [
                ("Icon final render", .low, nil, ["Design"], [], -1),
                ("TestFlight build 42", .medium, nil, ["Feature"], [], -2),
                ("Privacy nutrition labels", .low, nil, [], [], -3)
            ])
        ], labelLookup: label)

        // 2) Home Renovation — To-Do · Doing · Done.
        let home = BoardFactory.makeBoard(
            name: "Home Renovation", colorHex: 0xF0663B, symbolName: "house.fill",
            template: .todoDoingDone, sortIndex: 1, isPro: true, context: context
        )
        seedCards(into: home, context: context, now: now, plans: [
            ("To-Do", [
                ("Get 3 contractor quotes", .high, 2, ["Urgent"], ["Kitchen", "Bath", "Floors"], 1),
                ("Choose paint palette", .medium, 5, ["Design"], [], 0),
                ("Order kitchen tiles", .medium, 9, [], [], 0),
                ("Permit paperwork", .low, 20, [], [], 0)
            ]),
            ("Doing", [
                ("Demo old cabinets", .high, 0, ["Urgent"], ["Empty drawers", "Unscrew", "Haul out"], 1),
                ("Patch drywall", .medium, 1, [], [], 0)
            ]),
            ("Done", [
                ("Measure all rooms", .low, nil, [], [], -2),
                ("Set renovation budget", .medium, nil, [], [], -4),
                ("Clear the garage", .low, nil, [], [], -1)
            ])
        ], labelLookup: label)

        // 3) Content Calendar.
        let content = BoardFactory.makeBoard(
            name: "Content Calendar", colorHex: 0x6B5BFF, symbolName: "calendar",
            template: .contentCalendar, sortIndex: 2, isPro: true, context: context
        )
        seedCards(into: content, context: context, now: now, plans: [
            ("Idea", [
                ("\"Native vs cloud\" essay", .low, nil, ["Research"], [], 0),
                ("Short: board demo", .medium, 4, ["Marketing"], ["Script", "Record", "Edit"], 1),
                ("Newsletter #12 theme", .low, 7, [], [], 0)
            ]),
            ("Drafting", [
                ("Launch announcement", .high, 1, ["Marketing", "Urgent"], ["Hook", "Body", "CTA"], 1),
                ("Feature deep-dive: WIP limits", .medium, 3, ["Feature"], [], 0)
            ]),
            ("Editing", [
                ("Onboarding walkthrough", .medium, 2, ["Design"], ["Trim intro", "Captions"], 1)
            ]),
            ("Scheduled", [
                ("Tip Tuesday: labels", .low, 0, ["Marketing"], [], 0),
                ("Behind-the-scenes photo", .low, 1, [], [], 0)
            ]),
            ("Published", [
                ("Welcome post", .low, nil, ["Marketing"], [], -3),
                ("Roadmap teaser", .medium, nil, [], [], -5)
            ])
        ], labelLookup: label)
    }

    /// One card spec: (title, priority, dueOffsetDays?, labelNames, checklistTexts, completedOffsetDays).
    /// `completedOffsetDays` < 1 means completed that many days ago (used for Done columns).
    private typealias CardSpec = (String, Priority, Int?, [String], [String], Int)

    private static func seedCards(
        into board: Board,
        context: ModelContext,
        now: Date,
        plans: [(String, [CardSpec])],
        labelLookup: (String) -> Label?
    ) {
        for (columnName, specs) in plans {
            guard let column = board.columns.first(where: { $0.name == columnName }) else { continue }
            let isDoneColumn = board.doneColumn?.id == column.id
            for (i, spec) in specs.enumerated() {
                let due = spec.2.map { DateUtils.startOfDay(DateUtils.addDays($0, to: now)) }
                let card = Card(
                    title: spec.0,
                    notes: "",
                    sortIndex: i,
                    dueDate: due,
                    priority: spec.1,
                    createdDate: DateUtils.addDays(-Int.random(in: 1...20), to: now),
                    column: column
                )
                context.insert(card)
                column.cards.append(card)

                // Labels.
                for name in spec.3 {
                    if let l = labelLookup(name) {
                        card.labels.append(l)
                    }
                }

                // Checklist.
                for (ci, text) in spec.4.enumerated() {
                    // Mark earlier items done to show partial progress.
                    let done = ci < (spec.4.count) / 2
                    let item = ChecklistItem(text: text, isDone: done, sortIndex: ci, card: card)
                    context.insert(item)
                    card.checklist.append(item)
                }

                // Completion: cards in the done column get a completedDate in the past.
                if isDoneColumn {
                    let agoDays = max(1, abs(spec.5))
                    card.completedDate = DateUtils.addDays(-agoDays, to: now)
                }
            }
        }
    }
}
