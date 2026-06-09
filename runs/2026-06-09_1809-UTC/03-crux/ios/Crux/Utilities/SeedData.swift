import Foundation
import SwiftData

/// Seeds a realistic starter workspace on first launch so every screen has
/// content: 2 areas, several projects, ~55 tasks spread across today / overdue /
/// upcoming / anytime / someday, recurring tasks, ~15 logbook entries, subtasks,
/// and a handful of tags. Guarded so it runs at most once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Area>())) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date()
        func day(_ offset: Int, hour: Int = 9) -> Date {
            let base = cal.date(byAdding: .day, value: offset, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }

        // MARK: Tags
        let tagSpec: [(String, String)] = [
            ("Quick", "6A8E68"),
            ("Errand", "B07C4E"),
            ("Focus", "4A7C8C"),
            ("Waiting", "8C5A6E"),
            ("Email", "5E6B8C")
        ]
        let tags = tagSpec.map { Tag(name: $0.0, colorHex: $0.1) }
        tags.forEach { context.insert($0) }
        func tag(_ name: String) -> Tag? { tags.first { $0.name == name } }

        // MARK: Areas
        let personal = Area(name: "Personal", colorHex: "6A8E68", order: 0)
        let work = Area(name: "Work", colorHex: "4A7C8C", order: 1)
        context.insert(personal)
        context.insert(work)

        // MARK: Projects
        let home = Project(name: "Home & Errands", colorHex: "B07C4E", notes: "Around-the-house odds and ends.", order: 0)
        let health = Project(name: "Health", colorHex: "6A8E68", notes: "Move, eat, rest.", order: 1)
        let trip = Project(name: "Weekend Trip", colorHex: "8C5A6E", notes: "Pack and plan.", order: 2)
        home.area = personal; health.area = personal; trip.area = personal

        let launch = Project(name: "Q3 Launch", colorHex: "4A7C8C", notes: "Ship the new release.", order: 0)
        let website = Project(name: "Website Refresh", colorHex: "5E6B8C", notes: "New marketing site.", order: 1)
        let admin = Project(name: "Admin", colorHex: "9A8C5E", notes: "Keep the lights on.", order: 2)
        launch.area = work; website.area = work; admin.area = work

        let projects = [home, health, trip, launch, website, admin]
        projects.forEach { context.insert($0) }

        var order = 0
        func nextOrder() -> Int { defer { order += 1 }; return order }

        @discardableResult
        func make(_ title: String,
                  project: Project? = nil,
                  scheduled: Date? = nil,
                  due: Date? = nil,
                  priority: Priority = .none,
                  recurrence: Recurrence = .none,
                  interval: Int = 1,
                  someday: Bool = false,
                  notes: String = "",
                  tagNames: [String] = [],
                  done: Bool = false,
                  completedAt: Date? = nil,
                  subtasks: [(String, Bool)] = []) -> TaskItem {
            let task = TaskItem(title: title,
                                notes: notes,
                                isDone: done,
                                completedAt: completedAt,
                                dueDate: due,
                                scheduledDate: scheduled,
                                priority: priority,
                                recurrence: recurrence,
                                recurrenceInterval: interval,
                                isSomeday: someday,
                                sortOrder: nextOrder())
            task.project = project
            task.tags = tagNames.compactMap { tag($0) }
            context.insert(task)
            var so = 0
            for (st, stDone) in subtasks {
                let sub = Subtask(title: st, isDone: stDone, order: so); so += 1
                sub.task = task
                context.insert(sub)
            }
            return task
        }

        // MARK: Today
        make("Reply to Dana about the proposal", project: launch, scheduled: day(0, hour: 8), priority: .high, tagNames: ["Email"])
        make("Stretch for 10 minutes", project: health, scheduled: day(0, hour: 7), priority: .low, tagNames: ["Quick"])
        make("Buy oat milk and coffee", project: home, scheduled: day(0, hour: 18), tagNames: ["Errand", "Quick"])
        make("Review pull requests", project: launch, scheduled: day(0, hour: 10), priority: .medium, tagNames: ["Focus"])
        make("Book dentist appointment", project: health, scheduled: day(0, hour: 12), tagNames: ["Errand"])

        // MARK: Recurring (surface today)
        make("Daily standup", project: launch, scheduled: day(0, hour: 9), priority: .medium, recurrence: .daily, tagNames: ["Focus"])
        make("Take vitamins", project: health, scheduled: day(0, hour: 8), recurrence: .daily, tagNames: ["Quick"])
        make("Weekly review", project: nil, scheduled: day(0, hour: 17), priority: .medium, recurrence: .weekly, tagNames: ["Focus"])
        make("Pay monthly bills", project: admin, due: day(2, hour: 20), priority: .high, recurrence: .monthly, tagNames: ["Errand"])
        make("Water the plants", project: home, scheduled: day(0, hour: 19), recurrence: .everyN, interval: 3, tagNames: ["Quick"])

        // MARK: Overdue
        make("Submit expense report", project: admin, due: day(-2, hour: 17), priority: .high, tagNames: ["Email"])
        make("Renew gym membership", project: health, due: day(-1, hour: 12), priority: .medium, tagNames: ["Errand"])
        make("Send invoice to client", project: launch, due: day(-3, hour: 9), priority: .high, tagNames: ["Email", "Waiting"])

        // MARK: Upcoming (next ~30 days)
        make("Prepare launch slides", project: launch, scheduled: day(1, hour: 14), priority: .high, tagNames: ["Focus"],
             subtasks: [("Outline narrative", true), ("Design hero slide", false), ("Rehearse", false)])
        make("Grocery run", project: home, scheduled: day(1, hour: 11), tagNames: ["Errand"])
        make("1:1 with manager", project: nil, scheduled: day(2, hour: 15), priority: .medium)
        make("Draft website copy", project: website, due: day(3, hour: 17), priority: .medium, tagNames: ["Focus"])
        make("Pack for the trip", project: trip, scheduled: day(4, hour: 20), priority: .medium,
             subtasks: [("Clothes", false), ("Charger", false), ("Snacks", false), ("Tickets", true)])
        make("Drive to the coast", project: trip, scheduled: day(5, hour: 8), priority: .high)
        make("Dentist checkup", project: health, due: day(7, hour: 10), tagNames: ["Errand"])
        make("Quarterly metrics deck", project: launch, due: day(10, hour: 12), priority: .high, tagNames: ["Focus"])
        make("Update portfolio site", project: website, scheduled: day(12, hour: 13), priority: .low)
        make("Renew car registration", project: admin, due: day(18, hour: 17), priority: .medium, tagNames: ["Errand"])
        make("Plan birthday dinner", project: home, scheduled: day(21, hour: 19), tagNames: ["Quick"])
        make("Annual health screening", project: health, due: day(28, hour: 9), recurrence: .yearly)

        // MARK: Anytime (no dates)
        make("Read 'Deep Work'", project: nil, tagNames: ["Focus"])
        make("Clean out the garage", project: home, priority: .low)
        make("Back up photos", project: admin, tagNames: ["Quick"])
        make("Research standing desks", project: nil, tagNames: ["Waiting"])
        make("Fix squeaky door", project: home)
        make("Organize bookmarks", project: nil, tagNames: ["Quick"])
        make("Refactor onboarding flow", project: website, priority: .medium, tagNames: ["Focus"])
        make("Reply to old emails", project: nil, tagNames: ["Email"])

        // MARK: Someday
        make("Learn to make sourdough", project: nil, someday: true)
        make("Plan a hiking trip in the Alps", project: trip, someday: true)
        make("Take a pottery class", project: nil, someday: true, tagNames: ["Quick"])
        make("Write a short story", project: nil, someday: true, priority: .low)
        make("Build a standing greenhouse", project: home, someday: true)

        // MARK: Logbook (~15 completed over the past weeks)
        let logbook: [(String, Project?, Int, [String])] = [
            ("Submit Q2 report", launch, -1, ["Email"]),
            ("Morning run", health, -1, ["Quick"]),
            ("Call the bank", admin, -2, ["Errand"]),
            ("Finish wireframes", website, -2, ["Focus"]),
            ("Buy birthday gift", home, -3, ["Errand"]),
            ("Code review for Sam", launch, -3, ["Focus"]),
            ("Schedule team offsite", nil, -4, []),
            ("Replace air filter", home, -5, []),
            ("Update résumé", nil, -6, ["Focus"]),
            ("Pay credit card", admin, -7, ["Errand"]),
            ("Meal prep Sunday", health, -7, ["Quick"]),
            ("Archive old projects", admin, -9, []),
            ("Send thank-you notes", nil, -10, ["Email"]),
            ("Fix broken link", website, -12, ["Quick"]),
            ("Plan sprint", launch, -14, ["Focus"]),
            ("Deep clean kitchen", home, -16, [])
        ]
        for (title, project, offset, tagNames) in logbook {
            let completedDate = day(offset, hour: Int.random(in: 9...18))
            make(title, project: project, priority: .none, tagNames: tagNames, done: true, completedAt: completedDate)
        }

        do {
            try context.save()
        } catch {
            // First-run seed save failed; the app remains usable with an empty
            // store and the next launch will retry seeding.
        }
    }
}
