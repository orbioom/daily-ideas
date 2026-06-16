import Foundation
import SwiftData

/// Seeds realistic sample data on first launch (guarded so it runs once).
@MainActor
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        // Mileage rates are seeded independently so the engine always has rates.
        seedRatesIfNeeded(context)

        let tripCountDescriptor = FetchDescriptor<Trip>()
        let existing = (try? context.fetchCount(tripCountDescriptor)) ?? 0
        guard existing == 0 else { return }

        seedContent(context)
    }

    static func seedRatesIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<MileageRate>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        for rate in MileageRate.seed {
            context.insert(MileageRate(year: rate.year,
                                       businessRate: rate.businessRate,
                                       medicalRate: rate.medicalRate,
                                       charityRate: rate.charityRate))
        }
        try? context.save()
    }

    private static func seedContent(_ context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)

        // Vehicles
        let primary = Vehicle(name: "Daily Driver",
                              makeModel: "2021 Toyota RAV4",
                              startingOdometer: 18420,
                              isDefault: true)
        let secondary = Vehicle(name: "Weekend Van",
                                makeModel: "2018 Ford Transit",
                                startingOdometer: 64210,
                                isDefault: false)
        context.insert(primary)
        context.insert(secondary)

        // Favorite places (one-way miles)
        let favorites = [
            FavoritePlace(name: "Downtown Office", defaultMiles: 12.4),
            FavoritePlace(name: "Airport", defaultMiles: 27.8),
            FavoritePlace(name: "Warehouse", defaultMiles: 8.6),
            FavoritePlace(name: "Client — Riverside", defaultMiles: 19.2),
            FavoritePlace(name: "Supply Store", defaultMiles: 5.1)
        ]
        favorites.forEach { context.insert($0) }

        // Deterministic pseudo-random so seeds look natural but stable.
        var rng = SeededGenerator(seed: 0xF07_10_0001)

        let routes: [(String, String, Double, TripPurpose)] = [
            ("Home", "Downtown Office", 12.4, .business),
            ("Home", "Airport", 27.8, .business),
            ("Office", "Warehouse", 8.6, .business),
            ("Home", "Client — Riverside", 19.2, .business),
            ("Office", "Supply Store", 5.1, .business),
            ("Home", "Client — Northgate", 14.7, .business),
            ("Depot", "Delivery Loop", 31.5, .business),
            ("Home", "Clinic", 9.3, .medical),
            ("Home", "Food Bank", 6.8, .charity),
            ("Home", "Grocery", 4.2, .personal),
            ("Office", "Lunch Meeting", 3.6, .business),
            ("Home", "Job Site", 22.1, .business)
        ]
        let notesPool = ["", "Client meeting", "Pickup & drop-off", "Quarterly review",
                         "Site inspection", "Delivery run", "Volunteer shift", ""]

        // ~52 trips spread across the current year up to today.
        let monthsElapsed = max(1, calendar.component(.month, from: now))
        for i in 0..<52 {
            let route = routes[Int(rng.next() % UInt64(routes.count))]
            let monthOffset = Int(rng.next() % UInt64(monthsElapsed))
            let day = 1 + Int(rng.next() % 27)
            var comps = DateComponents()
            comps.year = year
            comps.month = monthOffset + 1
            comps.day = day
            comps.hour = 7 + Int(rng.next() % 11)
            let date = calendar.date(from: comps) ?? now
            guard date <= now else { continue }

            let jitter = Double(rng.next() % 30) / 10.0 - 1.5
            let miles = max(1.0, route.2 + jitter)
            let roundTrip = (rng.next() % 3) == 0
            let useOdometer = (rng.next() % 4) == 0

            let trip = Trip(date: date,
                            purpose: route.3,
                            miles: miles,
                            fromLabel: route.0,
                            toLabel: route.1,
                            roundTrip: roundTrip,
                            notes: notesPool[i % notesPool.count],
                            vehicle: (rng.next() % 5 == 0) ? secondary : primary)
            if useOdometer {
                let start = 20000 + Double(i) * 47
                trip.startOdometer = start
                trip.endOdometer = start + miles
            }
            context.insert(trip)
        }

        // ~22 expenses across categories.
        let expenseSpecs: [(ExpenseCategory, Double, Bool)] = [
            (.fuel, 58.40, true), (.fuel, 61.10, true), (.fuel, 49.95, true),
            (.fuel, 64.20, true), (.fuel, 52.75, true),
            (.maintenance, 189.00, true), (.maintenance, 432.50, true),
            (.insurance, 142.00, true), (.insurance, 142.00, true),
            (.tolls, 7.50, true), (.tolls, 12.25, true), (.tolls, 5.00, true),
            (.parking, 18.00, true), (.parking, 24.00, true),
            (.supplies, 36.99, true), (.supplies, 89.50, true),
            (.phone, 45.00, true), (.phone, 45.00, true),
            (.meals, 28.40, false), (.meals, 41.10, false),
            (.other, 19.99, true), (.other, 110.00, false)
        ]
        for (idx, spec) in expenseSpecs.enumerated() {
            let monthOffset = Int(rng.next() % UInt64(monthsElapsed))
            let day = 1 + Int(rng.next() % 27)
            var comps = DateComponents()
            comps.year = year
            comps.month = monthOffset + 1
            comps.day = day
            let date = calendar.date(from: comps) ?? now
            let amount = Decimal(spec.1)
            let expense = Expense(date: min(date, now),
                                  category: spec.0,
                                  amount: amount,
                                  deductible: spec.2,
                                  notes: "",
                                  vehicle: spec.0.isVehicleOperating ? primary : nil)
            _ = idx
            context.insert(expense)
        }

        try? context.save()
    }
}

/// Tiny deterministic generator (splitmix64) for stable, natural-looking seeds.
private struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
