import Foundation
import SwiftData

/// Realistic starter events seeded on first run so the app never opens empty for
/// a brand-new user. Inserted once (guarded by an `@AppStorage` flag in RootView).
enum SampleData {
    static func seed(into context: ModelContext, now: Date = Date()) {
        let cal = Calendar.current
        func day(_ offset: Int) -> Date {
            cal.startOfDay(for: cal.date(byAdding: .day, value: offset, to: now) ?? now)
        }
        func at(_ offset: Int, hour: Int, minute: Int) -> Date {
            let base = cal.date(byAdding: .day, value: offset, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let events: [CountdownEvent] = [
            CountdownEvent(title: "New Year's Day", date: nextNewYear(now: now, cal: cal),
                           includeTime: false, kind: .until, symbol: "fireworks",
                           colorTag: CardTheme.plum.rawValue, repeatRule: .yearly,
                           note: "A fresh start.", pinned: true,
                           createdAt: cal.date(byAdding: .day, value: -20, to: now) ?? now),
            CountdownEvent(title: "Weekend Getaway", date: at(9, hour: 8, minute: 30),
                           includeTime: true, kind: .until, symbol: "beach.umbrella.fill",
                           colorTag: CardTheme.ocean.rawValue, repeatRule: .none,
                           note: "Flight departs at 8:30.", pinned: true,
                           createdAt: cal.date(byAdding: .day, value: -6, to: now) ?? now),
            CountdownEvent(title: "Payday", date: day(12),
                           includeTime: false, kind: .until, symbol: "creditcard.fill",
                           colorTag: CardTheme.forest.rawValue, repeatRule: .monthly,
                           note: "", pinned: false,
                           createdAt: cal.date(byAdding: .day, value: -30, to: now) ?? now),
            CountdownEvent(title: "Started New Job", date: day(-42),
                           includeTime: false, kind: .since, symbol: "briefcase.fill",
                           colorTag: CardTheme.slate.rawValue, repeatRule: .none,
                           note: "First day at the studio.", pinned: false,
                           createdAt: day(-42)),
            CountdownEvent(title: "Anniversary", date: anniversary(now: now, cal: cal),
                           includeTime: false, kind: .until, symbol: "heart.fill",
                           colorTag: CardTheme.rose.rawValue, repeatRule: .yearly,
                           note: "", pinned: false,
                           createdAt: cal.date(byAdding: .day, value: -100, to: now) ?? now)
        ]

        for e in events { context.insert(e) }
        try? context.save()
    }

    private static func nextNewYear(now: Date, cal: Calendar) -> Date {
        let year = cal.component(.year, from: now)
        var c = DateComponents(); c.year = year + 1; c.month = 1; c.day = 1
        return cal.date(from: c) ?? now
    }

    private static func anniversary(now: Date, cal: Calendar) -> Date {
        // ~3 months out, on a fixed day, recurring yearly.
        let d = cal.date(byAdding: .month, value: 3, to: now) ?? now
        return cal.startOfDay(for: d)
    }
}
