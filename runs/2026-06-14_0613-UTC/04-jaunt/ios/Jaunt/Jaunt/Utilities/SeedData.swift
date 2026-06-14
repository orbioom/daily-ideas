import Foundation
import SwiftData

/// First-launch sample content. Builds two rich trips so the app feels alive
/// out of the box: one upcoming trip with a full multi-day itinerary, and one
/// completed trip. Idempotent behind the "didSeed" flag.
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "didSeed") else { return }
        seed(context: context)
        defaults.set(true, forKey: "didSeed")
    }

    /// Force a fresh seed (used by Settings → reset).
    static func seed(context: ModelContext) {
        let cal = ItineraryEngine.calendar
        let today = cal.startOfDay(for: Date())

        // Helper to build a date offset from today.
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: today) ?? today
        }
        func minutes(_ h: Int, _ m: Int) -> Int { h * 60 + m }

        // MARK: Trip 1 — Upcoming: Kyoto (5 days, rich itinerary)

        let kyotoStart = day(12)
        let kyotoEnd = day(16)
        let kyoto = Trip(name: "Kyoto in Autumn",
                         destination: "Kyoto, Japan",
                         startDate: kyotoStart,
                         endDate: kyotoEnd,
                         notes: "Maple season — book temples early. JR Pass activated on arrival.",
                         budgetAmount: 2400,
                         currencyCode: "USD",
                         coverHue: 0.03)
        context.insert(kyoto)
        TripService.syncDays(for: kyoto, context: context)
        let kyotoDays = TripService.orderedDays(kyoto)

        // Day 1 — Arrival (8 items)
        applyDay(kyotoDays, 0, title: "Arrival", context: context, items: [
            (.transport, "Flight lands at KIX", minutes(13, 40), 0, "Kansai Intl Airport", true, 0, "Terminal 1, immigration then JR desk"),
            (.transport, "Haruka Express to Kyoto", minutes(15, 0), 80, "KIX → Kyoto Stn", true, 0, "Reserved car 4"),
            (.lodging, "Check in: Machiya stay", minutes(17, 30), 30, "Gion district", true, 320, "Traditional townhouse, code 4471"),
            (.food, "Dinner — kaiseki at Gion Karyo", minutes(19, 0), 120, "Gion, Higashiyama", true, 95, "Reservation under our name"),
            (.activity, "Evening stroll Hanamikoji", minutes(21, 0), 45, "Hanamikoji St", false, 0, "Lantern-lit lane"),
            (.sight, "Tatsumi Bridge photo stop", minutes(21, 50), 15, "Shirakawa", false, 0, ""),
            (.shopping, "Convenience store run", -1, 20, "Lawson, Shijo", false, 12, "Breakfast + water"),
            (.other, "Plan tomorrow over tea", -1, 30, "", false, 0, "")
        ])

        // Day 2 — Temples east (9 items)
        applyDay(kyotoDays, 1, title: "Eastern Temples", context: context, items: [
            (.food, "Breakfast at machiya", minutes(7, 30), 30, "Stay", false, 0, ""),
            (.sight, "Kiyomizu-dera (early)", minutes(8, 30), 90, "Higashiyama", true, 5, "Beat the crowds"),
            (.activity, "Sannenzaka & Ninenzaka walk", minutes(10, 15), 60, "Higashiyama slopes", false, 0, "Souvenir lanes"),
            (.food, "Matcha + warabi mochi", minutes(11, 30), 40, "Sannenzaka café", false, 14, ""),
            (.sight, "Kodai-ji garden", minutes(12, 30), 60, "Kodaiji", true, 6, ""),
            (.food, "Lunch — yudofu", minutes(14, 0), 60, "Nanzenji area", false, 22, "Hot tofu set"),
            (.sight, "Philosopher's Path", minutes(15, 30), 75, "Sakyo", false, 0, "Maple corridor"),
            (.sight, "Ginkaku-ji (Silver Pavilion)", minutes(17, 0), 60, "Higashiyama", true, 5, ""),
            (.food, "Izakaya dinner", minutes(19, 30), 90, "Pontocho alley", true, 60, "Counter seats reserved")
        ])

        // Day 3 — Arashiyama (9 items)
        applyDay(kyotoDays, 2, title: "Arashiyama", context: context, items: [
            (.transport, "JR to Saga-Arashiyama", minutes(8, 0), 30, "Kyoto Stn", false, 4, ""),
            (.sight, "Bamboo Grove at opening", minutes(8, 45), 45, "Arashiyama", false, 0, "Go early, very busy"),
            (.sight, "Tenryu-ji garden", minutes(9, 45), 60, "Arashiyama", true, 8, "UNESCO site"),
            (.activity, "Monkey Park hike", minutes(11, 15), 90, "Iwatayama", true, 6, "Steep climb, great view"),
            (.food, "Lunch by the river", minutes(13, 30), 60, "Togetsukyo Bridge", false, 25, ""),
            (.transport, "Sagano Romantic train", minutes(15, 0), 50, "Torokko line", true, 12, "Reserved, window side"),
            (.sight, "Okochi Sanso villa", minutes(16, 30), 60, "Arashiyama", true, 9, "Includes tea"),
            (.shopping, "Craft shops browse", minutes(17, 45), 45, "Main street", false, 30, ""),
            (.food, "Ramen dinner back in town", minutes(20, 0), 60, "Kyoto Stn", false, 16, "")
        ])

        // Day 4 — Fushimi + Nara day trip (9 items)
        applyDay(kyotoDays, 3, title: "Fushimi & Nara", context: context, items: [
            (.sight, "Fushimi Inari at sunrise", minutes(6, 30), 120, "Fushimi", false, 0, "Climb before crowds"),
            (.food, "Street breakfast at base", minutes(9, 0), 30, "Fushimi shops", false, 10, "Grilled skewers"),
            (.transport, "Train to Nara", minutes(10, 0), 60, "Kintetsu line", false, 7, ""),
            (.activity, "Feed the deer", minutes(11, 30), 45, "Nara Park", false, 3, "Buy shika senbei"),
            (.sight, "Todai-ji Great Buddha", minutes(12, 30), 75, "Nara Park", true, 6, ""),
            (.food, "Lunch — kakinoha sushi", minutes(14, 0), 60, "Nara", false, 18, "Persimmon-leaf sushi"),
            (.sight, "Kasuga Taisha lanterns", minutes(15, 30), 60, "Nara", false, 5, ""),
            (.transport, "Return to Kyoto", minutes(17, 30), 60, "Kintetsu line", false, 7, ""),
            (.food, "Farewell dinner — Obanzai", minutes(19, 30), 120, "Downtown Kyoto", true, 70, "Seasonal small plates")
        ])

        // Day 5 — Departure (7 items)
        applyDay(kyotoDays, 4, title: "Departure", context: context, items: [
            (.food, "Last machiya breakfast", minutes(8, 0), 40, "Stay", false, 0, ""),
            (.shopping, "Nishiki Market gifts", minutes(9, 30), 75, "Nishiki", false, 45, "Tea, knives, sweets"),
            (.lodging, "Check out & store bags", minutes(11, 0), 20, "Stay", false, 0, "Luggage to station"),
            (.sight, "Last walk Kamogawa river", minutes(11, 30), 45, "Pontocho side", false, 0, ""),
            (.food, "Bento for the train", -1, 20, "Kyoto Stn", false, 12, "Ekiben"),
            (.transport, "Haruka to KIX", minutes(14, 0), 80, "Kyoto Stn", true, 0, "Reserved"),
            (.transport, "Flight home", minutes(17, 30), 0, "Kansai Intl", true, 0, "Terminal 1")
        ])

        // Kyoto packing (mix of packed states)
        applyPacking(kyoto, context: context, items: [
            ("Passport", .documents, true, 1),
            ("JR Pass voucher", .documents, true, 1),
            ("Travel insurance card", .documents, false, 1),
            ("Yen cash", .essentials, false, 1),
            ("Pocket wifi", .electronics, true, 1),
            ("Phone + charger", .electronics, true, 1),
            ("Power adapter (Type A)", .electronics, false, 1),
            ("Light layers", .clothing, false, 4),
            ("Rain shell", .clothing, false, 1),
            ("Comfortable walking shoes", .clothing, true, 1),
            ("Scarf", .clothing, false, 1),
            ("Toiletry kit", .toiletries, false, 1),
            ("Hand sanitizer", .toiletries, true, 1),
            ("Reusable bottle", .other, false, 1),
            ("Foldable day bag", .essentials, false, 1)
        ])

        // Kyoto expenses (planning-stage logged spend)
        applyExpenses(kyoto, context: context, items: [
            ("Flights", .transport, 980, day(-20)),
            ("Machiya deposit", .lodging, 160, day(-14)),
            ("JR Pass", .transport, 280, day(-7)),
            ("Travel insurance", .other, 64, day(-7))
        ])

        // MARK: Trip 2 — Completed: Lisbon (4 days)

        let lisbonStart = day(-40)
        let lisbonEnd = day(-37)
        let lisbon = Trip(name: "Lisbon Long Weekend",
                          destination: "Lisbon, Portugal",
                          startDate: lisbonStart,
                          endDate: lisbonEnd,
                          notes: "Sunny, hilly, lots of tiles. Tram 28 is touristy but worth it once.",
                          budgetAmount: 900,
                          currencyCode: "EUR",
                          coverHue: 0.12)
        context.insert(lisbon)
        TripService.syncDays(for: lisbon, context: context)
        let lisbonDays = TripService.orderedDays(lisbon)

        applyDay(lisbonDays, 0, title: "Alfama", context: context, items: [
            (.lodging, "Check in — Alfama guesthouse", minutes(14, 0), 30, "Alfama", true, 0, ""),
            (.sight, "São Jorge Castle", minutes(16, 0), 90, "Castelo", true, 10, "Sunset views"),
            (.food, "Tasca dinner — bacalhau", minutes(20, 0), 90, "Alfama lanes", false, 28, ""),
            (.activity, "Fado evening", minutes(22, 0), 60, "Alfama", true, 20, "")
        ])
        applyDay(lisbonDays, 1, title: "Belém", context: context, items: [
            (.transport, "Tram to Belém", minutes(9, 0), 30, "Tram 15", false, 3, ""),
            (.sight, "Jerónimos Monastery", minutes(9, 45), 75, "Belém", true, 12, ""),
            (.food, "Pastéis de Belém", minutes(11, 15), 30, "Belém", false, 6, "The original"),
            (.sight, "Belém Tower", minutes(12, 0), 45, "Riverfront", true, 8, ""),
            (.food, "Seafood lunch", minutes(13, 30), 75, "Cais do Sodré", false, 34, "")
        ])
        applyDay(lisbonDays, 2, title: "Sintra day trip", context: context, items: [
            (.transport, "Train to Sintra", minutes(8, 30), 45, "Rossio Stn", false, 5, ""),
            (.sight, "Pena Palace", minutes(10, 0), 120, "Sintra hills", true, 20, "Book timed entry"),
            (.sight, "Quinta da Regaleira", minutes(13, 0), 90, "Sintra", true, 12, "Initiation well"),
            (.food, "Travesseiros pastry", minutes(15, 0), 30, "Sintra town", false, 5, "")
        ])
        applyDay(lisbonDays, 3, title: "Departure", context: context, items: [
            (.shopping, "Tile shop souvenirs", minutes(10, 0), 60, "Chiado", false, 40, ""),
            (.food, "Last bifana", minutes(12, 0), 30, "Baixa", false, 8, ""),
            (.transport, "Airport transfer", minutes(14, 0), 30, "Aeroporto", true, 25, "")
        ])

        applyPacking(lisbon, context: context, items: [
            ("Passport", .documents, true, 1),
            ("Sunglasses", .essentials, true, 1),
            ("Sunscreen", .toiletries, true, 1),
            ("Light shirts", .clothing, true, 4),
            ("Walking sandals", .clothing, true, 1),
            ("Phone charger", .electronics, true, 1),
            ("Day bag", .essentials, true, 1)
        ])
        applyExpenses(lisbon, context: context, items: [
            ("Flights", .transport, 210, lisbonStart),
            ("Guesthouse", .lodging, 280, lisbonStart),
            ("Meals", .food, 190, day(-38)),
            ("Sintra tickets", .sight, 64, day(-38)),
            ("Trams & metro", .transport, 28, day(-37))
        ])
    }

    // MARK: - Builders

    private static func applyDay(_ days: [TripDay],
                                 _ index: Int,
                                 title: String,
                                 context: ModelContext,
                                 items: [(ItemCategory, String, Int, Int, String, Bool, Double, String)]) {
        guard index >= 0, index < days.count else { return }
        let day = days[index]
        day.title = title
        for (sortIdx, spec) in items.enumerated() {
            let item = ItineraryItem(title: spec.1,
                                     category: spec.0,
                                     startTimeMinutes: spec.2,
                                     durationMin: spec.3,
                                     address: spec.4,
                                     notes: spec.7,
                                     cost: spec.6,
                                     booked: spec.5,
                                     sortOrder: sortIdx)
            context.insert(item)
            item.day = day
        }
    }

    private static func applyPacking(_ trip: Trip,
                                     context: ModelContext,
                                     items: [(String, PackCategory, Bool, Int)]) {
        for spec in items {
            let p = PackItem(name: spec.0, category: spec.1, packed: spec.2, quantity: spec.3)
            context.insert(p)
            p.trip = trip
        }
    }

    private static func applyExpenses(_ trip: Trip,
                                      context: ModelContext,
                                      items: [(String, ItemCategory, Double, Date)]) {
        for spec in items {
            let e = Expense(title: spec.0, category: spec.1, amount: spec.2, date: spec.3)
            context.insert(e)
            e.trip = trip
        }
    }
}
