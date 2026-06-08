import Foundation
import SwiftData

enum SeedData {
    @MainActor
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // An upcoming trip with a realistic itinerary, stays, packing, budget.
        guard let start = cal.date(byAdding: .day, value: 21, to: today),
              let end = cal.date(byAdding: .day, value: 25, to: today) else { return }

        let trip = Trip(name: "Lisbon Long Weekend",
                        destination: "Lisbon, Portugal",
                        startDate: start, endDate: end,
                        notes: "First time in Portugal. Slow mornings, pastéis, lots of walking.",
                        colorHex: 0x3E8E9E, currencyCode: "EUR", budget: 1200)
        context.insert(trip)

        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let day = cal.date(byAdding: .day, value: dayOffset, to: start) ?? start
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let acts: [Activity] = [
            Activity(title: "Flight TP1234 → Lisbon", startTime: at(0, 9, 30), category: .transport, location: "LIS Airport", cost: 180, booked: true, trip: trip),
            Activity(title: "Check in & wander Alfama", startTime: at(0, 15), category: .sightseeing, location: "Alfama", trip: trip),
            Activity(title: "Dinner — Time Out Market", startTime: at(0, 20), category: .food, location: "Cais do Sodré", cost: 35, trip: trip),
            Activity(title: "Belém Tower & Jerónimos", startTime: at(1, 10), category: .sightseeing, location: "Belém", cost: 18, booked: true, trip: trip),
            Activity(title: "Pastéis de Belém", startTime: at(1, 13), category: .food, location: "Belém", cost: 6, trip: trip),
            Activity(title: "Tram 28 ride", startTime: at(1, 16, 30), category: .activity, location: "Martim Moniz", cost: 3, trip: trip),
            Activity(title: "Day trip to Sintra", startTime: at(2, 9), category: .activity, location: "Sintra", cost: 45, booked: true, trip: trip),
            Activity(title: "Free morning", startTime: at(3, 0), hasTime: false, category: .other, trip: trip),
            Activity(title: "Flight home", startTime: at(4, 12), category: .transport, location: "LIS Airport", booked: true, trip: trip),
        ]
        acts.forEach { context.insert($0) }

        let stay = Lodging(name: "Casa do Bairro",
                           address: "R. da Rosa, Bairro Alto",
                           checkIn: at(0, 15), checkOut: at(4, 11),
                           cost: 520, confirmation: "BK-99213", trip: trip)
        context.insert(stay)

        let packing: [PackingItem] = [
            PackingItem(name: "Passport", category: .documents, packed: true, order: 0, trip: trip),
            PackingItem(name: "Phone charger", category: .electronics, order: 1, trip: trip),
            PackingItem(name: "Walking shoes", category: .clothing, packed: true, order: 2, trip: trip),
            PackingItem(name: "Light jacket", category: .clothing, order: 3, trip: trip),
            PackingItem(name: "Sunscreen", category: .toiletries, order: 4, trip: trip),
            PackingItem(name: "Travel adapter", category: .electronics, order: 5, trip: trip),
        ]
        packing.forEach { context.insert($0) }

        let expenses: [Expense] = [
            Expense(title: "Flights", amount: 180, category: .transport, date: today, trip: trip),
            Expense(title: "Hotel deposit", amount: 160, category: .lodging, date: today, trip: trip),
        ]
        expenses.forEach { context.insert($0) }

        // A past trip for the "completed" state.
        if let pStart = cal.date(byAdding: .day, value: -120, to: today),
           let pEnd = cal.date(byAdding: .day, value: -114, to: today) {
            let past = Trip(name: "Kyoto in Autumn", destination: "Kyoto, Japan",
                            startDate: pStart, endDate: pEnd, colorHex: 0xB0814E,
                            currencyCode: "JPY", budget: 0)
            context.insert(past)
        }

        try? context.save()
    }
}
