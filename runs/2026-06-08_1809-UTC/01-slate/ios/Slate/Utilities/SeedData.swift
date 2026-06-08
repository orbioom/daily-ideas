import Foundation
import SwiftData

/// Seeds a realistic day and a small template library on first run so the
/// app never opens empty.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let blockCount = (try? context.fetchCount(FetchDescriptor<TimeBlock>())) ?? 0
        let templateCount = (try? context.fetchCount(FetchDescriptor<BlockTemplate>())) ?? 0
        if blockCount == 0 { seedBlocks(context) }
        if templateCount == 0 { seedTemplates(context) }
        try? context.save()
    }

    private static func at(_ day: Date, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func seedBlocks(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        func add(_ title: String, _ h: Int, _ m: Int, _ dur: Int, _ cat: BlockCategory,
                 done: Bool = false, checklist: [String] = []) {
            let b = TimeBlock(title: title, start: at(today, h, m),
                              durationMinutes: dur, category: cat, isDone: done)
            context.insert(b)
            for (i, c) in checklist.enumerated() {
                let item = ChecklistItem(title: c, order: i)
                item.block = b
                context.insert(item)
            }
        }

        add("Morning workout", 6, 30, 45, .health, done: true)
        add("Plan the day", 8, 0, 20, .personal, done: true)
        add("Deep work — feature spec", 9, 0, 120, .focus, checklist: ["Outline", "Draft", "Review"])
        add("Team standup", 11, 0, 30, .work)
        add("Lunch & walk", 12, 30, 60, .rest)
        add("Design review", 14, 0, 60, .work)
        add("Read — 20 pages", 16, 30, 30, .learning)
        add("Dinner with friends", 19, 0, 90, .social)

        // a lighter tomorrow
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today
        let b1 = TimeBlock(title: "Inbox zero", start: at(tomorrow, 9, 0),
                           durationMinutes: 45, category: .work)
        let b2 = TimeBlock(title: "Gym", start: at(tomorrow, 18, 0),
                           durationMinutes: 60, category: .health)
        context.insert(b1); context.insert(b2)
    }

    private static func seedTemplates(_ context: ModelContext) {
        let templates = [
            BlockTemplate(title: "Morning workout", defaultStartMinute: 6 * 60 + 30,
                          durationMinutes: 45, category: .health),
            BlockTemplate(title: "Deep work", defaultStartMinute: 9 * 60,
                          durationMinutes: 120, category: .focus),
            BlockTemplate(title: "Email & admin", defaultStartMinute: 13 * 60,
                          durationMinutes: 30, category: .work),
            BlockTemplate(title: "Evening reading", defaultStartMinute: 21 * 60,
                          durationMinutes: 30, category: .learning),
        ]
        templates.forEach { context.insert($0) }
    }
}
