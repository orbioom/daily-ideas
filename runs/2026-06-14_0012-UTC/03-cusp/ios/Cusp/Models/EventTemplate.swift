import Foundation

/// A quick-add template that prefills the editor with sensible defaults for a
/// common occasion. Pure value type — never persisted.
struct EventTemplate: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let kind: EventKind
    let repeatRule: RepeatRule
    let themeTag: Int
    /// How to seed the default date relative to "now".
    let dateSeed: DateSeed

    enum DateSeed {
        /// The next January 1st.
        case nextNewYear
        /// `months` ahead at midnight.
        case monthsAhead(Int)
        /// `days` ahead at midnight.
        case daysAhead(Int)
        /// `years` ahead, used for long horizons like retirement.
        case yearsAhead(Int)
    }

    /// Resolve the seed into a concrete starting date.
    func seedDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        switch dateSeed {
        case .nextNewYear:
            let year = calendar.component(.year, from: now)
            var comps = DateComponents()
            comps.year = year + 1
            comps.month = 1
            comps.day = 1
            return calendar.date(from: comps) ?? now
        case .monthsAhead(let m):
            let d = calendar.date(byAdding: .month, value: m, to: now) ?? now
            return calendar.startOfDay(for: d)
        case .daysAhead(let days):
            let d = calendar.date(byAdding: .day, value: days, to: now) ?? now
            return calendar.startOfDay(for: d)
        case .yearsAhead(let y):
            let d = calendar.date(byAdding: .year, value: y, to: now) ?? now
            return calendar.startOfDay(for: d)
        }
    }

    static let gallery: [EventTemplate] = [
        EventTemplate(title: "New Year", subtitle: "Ring in the next year",
                      symbol: "fireworks", kind: .until, repeatRule: .yearly,
                      themeTag: CardTheme.plum.rawValue, dateSeed: .nextNewYear),
        EventTemplate(title: "Birthday", subtitle: "A yearly celebration",
                      symbol: "birthday.cake.fill", kind: .until, repeatRule: .yearly,
                      themeTag: CardTheme.rose.rawValue, dateSeed: .monthsAhead(1)),
        EventTemplate(title: "Anniversary", subtitle: "Mark the years together",
                      symbol: "heart.fill", kind: .until, repeatRule: .yearly,
                      themeTag: CardTheme.coral.rawValue, dateSeed: .monthsAhead(2)),
        EventTemplate(title: "Vacation", subtitle: "Count down to the trip",
                      symbol: "beach.umbrella.fill", kind: .until, repeatRule: .none,
                      themeTag: CardTheme.ocean.rawValue, dateSeed: .monthsAhead(1)),
        EventTemplate(title: "Exam", subtitle: "Stay on track",
                      symbol: "graduationcap.fill", kind: .until, repeatRule: .none,
                      themeTag: CardTheme.slate.rawValue, dateSeed: .daysAhead(30)),
        EventTemplate(title: "Payday", subtitle: "The monthly wait",
                      symbol: "creditcard.fill", kind: .until, repeatRule: .monthly,
                      themeTag: CardTheme.forest.rawValue, dateSeed: .daysAhead(14)),
        EventTemplate(title: "Retirement", subtitle: "The long horizon",
                      symbol: "sun.max.fill", kind: .until, repeatRule: .none,
                      themeTag: CardTheme.amber.rawValue, dateSeed: .yearsAhead(10)),
        EventTemplate(title: "Wedding", subtitle: "The big day",
                      symbol: "party.popper.fill", kind: .until, repeatRule: .none,
                      themeTag: CardTheme.dusk.rawValue, dateSeed: .monthsAhead(6))
    ]
}
