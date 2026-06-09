import Foundation

/// Pure, deterministic logic over people, occasions, and gifts: date roll-forward
/// for annual occasions and birthdays, countdowns, spend & budget rollups, and
/// chartable series. Kept separate from views so it stays testable and never
/// force-unwraps a date.
enum GiftEngine {

    // MARK: - Upcoming surfacing

    /// An item shown on Home: either a saved occasion or a person's birthday.
    struct Upcoming: Identifiable {
        enum Kind { case occasion, birthday }
        let id: String
        let kind: Kind
        let title: String
        let subtitle: String
        let date: Date
        let daysAway: Int
        let occasion: Occasion?
        let person: Person?
    }

    // MARK: - Date roll-forward

    /// The next time an occasion happens at or after `now`. Annual occasions roll
    /// their month/day forward across years; one-off occasions return their date.
    /// Feb 29 falls back to Feb 28 in non-leap years. Never force-unwraps.
    static func nextOccurrence(of occasion: Occasion,
                               from now: Date = .now,
                               calendar: Calendar = .current) -> Date {
        guard occasion.isAnnual else { return occasion.date }
        return nextAnnual(of: occasion.date, from: now, calendar: calendar) ?? occasion.date
    }

    /// The person's next birthday at or after `now`, or nil if none is set.
    static func nextBirthday(for person: Person,
                             from now: Date = .now,
                             calendar: Calendar = .current) -> Date? {
        guard let birthday = person.birthday else { return nil }
        return nextAnnual(of: birthday, from: now, calendar: calendar)
    }

    /// Rolls a month/day forward to the next occurrence at or after the start of
    /// `now`'s day. Returns nil only if the calendar cannot build any candidate.
    private static func nextAnnual(of source: Date,
                                   from now: Date,
                                   calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        let comps = calendar.dateComponents([.month, .day], from: source)
        guard let month = comps.month, let day = comps.day else { return nil }
        let currentYear = calendar.component(.year, from: today)

        // Try this year, then subsequent years, with a Feb 29 fallback.
        for yearOffset in 0...4 {
            let year = currentYear + yearOffset
            if let candidate = dateFor(year: year, month: month, day: day, calendar: calendar),
               calendar.startOfDay(for: candidate) >= today {
                return candidate
            }
        }
        // Fallback: this year's date even if it's already passed.
        return dateFor(year: currentYear, month: month, day: day, calendar: calendar)
    }

    /// Builds a date, gracefully handling Feb 29 in non-leap years (→ Feb 28).
    private static func dateFor(year: Int, month: Int, day: Int,
                                calendar: Calendar) -> Date? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let date = calendar.date(from: comps),
           calendar.component(.day, from: date) == day {
            return date
        }
        // Day didn't exist (e.g. Feb 29) — clamp to the last valid day of month.
        var fallback = DateComponents()
        fallback.year = year
        fallback.month = month
        fallback.day = 28
        return calendar.date(from: fallback)
    }

    /// Whole days from the start of `now` to the start of `date` (can be negative).
    static func daysAway(_ date: Date,
                         from now: Date = .now,
                         calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: now)
        let b = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    // MARK: - Combined upcoming feed

    /// Upcoming occasions and birthdays, ascending by date. Pass `within` to cap
    /// how far ahead to look (in days); nil includes everything upcoming.
    static func upcoming(occasions: [Occasion],
                         people: [Person],
                         from now: Date = .now,
                         within days: Int? = nil,
                         calendar: Calendar = .current) -> [Upcoming] {
        var items: [Upcoming] = []

        for occasion in occasions {
            let date = nextOccurrence(of: occasion, from: now, calendar: calendar)
            let away = daysAway(date, from: now, calendar: calendar)
            guard away >= 0 else { continue }
            if let cap = days, away > cap { continue }
            items.append(Upcoming(
                id: "occasion-\(occasion.persistentModelID.hashValue)",
                kind: .occasion,
                title: occasion.name,
                subtitle: occasion.isAnnual ? "Annual" : "One-time",
                date: date,
                daysAway: away,
                occasion: occasion,
                person: nil))
        }

        for person in people {
            guard let date = nextBirthday(for: person, from: now, calendar: calendar) else { continue }
            let away = daysAway(date, from: now, calendar: calendar)
            guard away >= 0 else { continue }
            if let cap = days, away > cap { continue }
            items.append(Upcoming(
                id: "birthday-\(person.persistentModelID.hashValue)",
                kind: .birthday,
                title: "\(person.name)'s Birthday",
                subtitle: person.relation,
                date: date,
                daysAway: away,
                occasion: nil,
                person: person))
        }

        return items.sorted { $0.date < $1.date }
    }

    /// Occasions only, ascending, as (occasion, nextDate, daysAway) tuples.
    static func upcomingOccasions(_ occasions: [Occasion],
                                  from now: Date = .now,
                                  within days: Int? = nil,
                                  calendar: Calendar = .current)
        -> [(occasion: Occasion, date: Date, daysAway: Int)] {
        var out: [(Occasion, Date, Int)] = []
        for occasion in occasions {
            let date = nextOccurrence(of: occasion, from: now, calendar: calendar)
            let away = daysAway(date, from: now, calendar: calendar)
            guard away >= 0 else { continue }
            if let cap = days, away > cap { continue }
            out.append((occasion, date, away))
        }
        return out.sorted { $0.1 < $1.1 }
            .map { (occasion: $0.0, date: $0.1, daysAway: $0.2) }
    }

    // MARK: - Spend & budgets

    static func spend(for person: Person) -> Double {
        person.gifts.filter { $0.isAcquired }.reduce(0) { $0 + $1.price }
    }

    static func spend(for occasion: Occasion) -> Double {
        occasion.gifts.filter { $0.isAcquired }.reduce(0) { $0 + $1.price }
    }

    static func totalSpend(_ gifts: [Gift]) -> Double {
        gifts.filter { $0.isAcquired }.reduce(0) { $0 + $1.price }
    }

    static func totalBudget(_ occasions: [Occasion]) -> Double {
        occasions.reduce(0) { $0 + max(0, $1.budget) }
    }

    struct BudgetStatus {
        let spent: Double
        let budget: Double
        let remaining: Double
        let overBudget: Bool
        /// 0…1 fraction of budget spent (0 when no budget is set).
        let fraction: Double
    }

    static func budgetStatus(for occasion: Occasion) -> BudgetStatus {
        let spent = spend(for: occasion)
        let budget = max(0, occasion.budget)
        let remaining = budget - spent
        let over = budget > 0 && spent > budget
        let fraction = budget > 0 ? min(spent / budget, 1) : 0
        return BudgetStatus(spent: spent, budget: budget,
                            remaining: remaining, overBudget: over, fraction: fraction)
    }

    // MARK: - Tallies

    static func statusTally(_ gifts: [Gift]) -> [GiftStatus: Int] {
        var tally: [GiftStatus: Int] = [:]
        for gift in gifts { tally[gift.status, default: 0] += 1 }
        return tally
    }

    /// Count of ideas not yet acquired — the "to buy" headline number.
    static func toBuyCount(_ gifts: [Gift]) -> Int {
        gifts.filter { !$0.isAcquired }.count
    }

    // MARK: - Chart series

    struct NamedSpend: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
    }

    /// Acquired spend grouped by person, descending. Skips zero-spend people.
    static func spendByPerson(_ people: [Person]) -> [NamedSpend] {
        people.map { NamedSpend(name: $0.name, amount: spend(for: $0)) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    /// Acquired spend grouped by occasion, descending. Skips zero-spend occasions.
    static func spendByOccasion(_ occasions: [Occasion]) -> [NamedSpend] {
        occasions.map { NamedSpend(name: $0.name, amount: spend(for: $0)) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }
}
