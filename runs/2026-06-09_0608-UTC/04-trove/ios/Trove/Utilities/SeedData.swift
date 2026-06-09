import Foundation
import SwiftData

/// Seeds a small, friendly set of people, occasions, and gifts on first launch so
/// Home, lists, and charts are never empty for a brand-new user. Dates are set
/// relative to now so countdowns and budgets look alive.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Person>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date.now

        func daysFromNow(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: d, to: now) ?? now
        }
        func yearsAgoBirthday(years: Int, inDays: Int) -> Date {
            // A birthday whose next occurrence is `inDays` away.
            let next = daysFromNow(inDays)
            return cal.date(byAdding: .year, value: -years, to: next) ?? next
        }

        // People
        let mom = Person(name: "Mom", relation: "Family",
                         notes: "Loves gardening and good tea.",
                         birthday: yearsAgoBirthday(years: 58, inDays: 12),
                         sizesNote: "Sweater M, shoe 8", sortIndex: 0)
        let alex = Person(name: "Alex", relation: "Partner",
                          notes: "Into film photography lately.",
                          birthday: yearsAgoBirthday(years: 31, inDays: 47),
                          sizesNote: "Shirt L, shoe 10.5", sortIndex: 1)
        let priya = Person(name: "Priya", relation: "Friend",
                           notes: "Coffee snob, plant collector.",
                           birthday: yearsAgoBirthday(years: 29, inDays: 95),
                           sizesNote: "", sortIndex: 2)
        let sam = Person(name: "Sam", relation: "Colleague",
                         notes: "Secret Santa this year.",
                         birthday: nil, sizesNote: "", sortIndex: 3)
        [mom, alex, priya, sam].forEach { context.insert($0) }

        // Occasions
        let holidays = Occasion(name: "Holidays", date: daysFromNow(34),
                                isAnnual: true,
                                notes: "Whole family gathering.",
                                budget: 400, sortIndex: 0)
        let anniversary = Occasion(name: "Anniversary", date: daysFromNow(60),
                                   isAnnual: true,
                                   notes: "Something thoughtful.",
                                   budget: 150, sortIndex: 1)
        let housewarming = Occasion(name: "Priya's Housewarming", date: daysFromNow(9),
                                    isAnnual: false,
                                    notes: "New apartment!",
                                    budget: 60, sortIndex: 2)
        [holidays, anniversary, housewarming].forEach { context.insert($0) }

        // Gifts across statuses and prices.
        let gifts: [Gift] = [
            Gift(title: "Ceramic teapot", notes: "The matte green one she liked.",
                 price: 48, status: .bought, store: "East Fork",
                 link: "https://example.com/teapot", person: mom, occasion: holidays),
            Gift(title: "Garden gloves & seeds", price: 22, status: .idea,
                 store: "", link: "", person: mom, occasion: holidays),
            Gift(title: "Film roll bundle", notes: "Portra 400 x3",
                 price: 54, status: .wrapped, store: "B&H",
                 link: "", person: alex, occasion: anniversary),
            Gift(title: "Leather camera strap", price: 65, status: .idea,
                 store: "", link: "https://example.com/strap",
                 person: alex, occasion: anniversary),
            Gift(title: "Pour-over kit", price: 38, status: .given,
                 store: "Local roaster", link: "",
                 person: priya, occasion: housewarming),
            Gift(title: "Trailing pothos", price: 18, status: .bought,
                 store: "Plant shop", link: "",
                 person: priya, occasion: housewarming),
            Gift(title: "Nice notebook", price: 24, status: .idea,
                 store: "", link: "", person: sam, occasion: holidays),
            Gift(title: "Mystery candle", price: 0, status: .idea,
                 store: "", link: "", person: nil, occasion: holidays)
        ]
        gifts.forEach { context.insert($0) }

        try? context.save()
    }
}
