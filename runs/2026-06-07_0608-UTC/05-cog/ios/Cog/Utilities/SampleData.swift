import Foundation
import SwiftData

/// Seeds two bikes with components, a season of rides, and service history.
enum SampleData {

    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        init(_ s: UInt64) { state = s == 0 ? 0xDEADBEEF12345 : s }
        mutating func next() -> UInt64 {
            state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
        }
    }

    static func seed(into context: ModelContext) {
        var rng = Seeded(2024)
        let cal = Calendar.current

        // Road bike with a chunk of mileage
        let road = Bike(name: "Carbon Road", kind: "Road", odometerKm: 8420)
        context.insert(road)
        addComponent(context, road, "Chain", "Drivetrain", at: 6200, km: 3500)
        addComponent(context, road, "Cassette", "Drivetrain", at: 0, km: 10000)
        addComponent(context, road, "Rear tyre", "Tyres", at: 5800, km: 3500)
        addComponent(context, road, "Front tyre", "Tyres", at: 4000, km: 5000)
        addComponent(context, road, "Brake pads (rear)", "Brakes", at: 6500, km: 3000)
        addComponent(context, road, "Bar tape", "Cockpit", at: 0, km: 0, days: 365, installedDaysAgo: 300)

        // Gravel bike
        let gravel = Bike(name: "Steel Gravel", kind: "Gravel", odometerKm: 3150)
        context.insert(gravel)
        addComponent(context, gravel, "Chain", "Drivetrain", at: 1900, km: 3000)
        addComponent(context, gravel, "Tubeless sealant", "Tyres", at: 0, km: 0, days: 120, installedDaysAgo: 95)
        addComponent(context, gravel, "Brake pads (front)", "Brakes", at: 900, km: 4000)
        addComponent(context, gravel, "Cassette", "Drivetrain", at: 0, km: 9000)

        // Rides over the last ~120 days
        for bike in [road, gravel] {
            let target = bike === road ? 8420.0 : 3150.0
            var accumulated = 0.0
            var rides: [(Date, Double)] = []
            for dayBack in stride(from: 120, through: 0, by: -1) {
                // ride roughly 3-4x per week
                if rng.next() % 10 < 4 {
                    let dist = bike === road ? Double(25 + rng.next() % 70) : Double(18 + rng.next() % 55)
                    let date = cal.date(byAdding: .day, value: -dayBack, to: Date()) ?? Date()
                    rides.append((date, dist))
                    accumulated += dist
                }
            }
            // scale rides so they sum to a sensible share of odometer (last 120 days portion)
            let scale = min(1.0, (target * 0.55) / max(1, accumulated))
            for (date, dist) in rides {
                let r = Ride(date: date, distanceKm: (dist * scale).rounded())
                r.bike = bike
                context.insert(r)
            }
        }

        // Service history
        let svc1 = ServiceRecord(date: daysAgo(48), componentName: "Chain", action: "Replaced",
                                 atKm: 6200, cost: 32, notes: "0.5% stretch — swapped early.")
        svc1.bike = road; context.insert(svc1)
        let svc2 = ServiceRecord(date: daysAgo(20), componentName: "Brake pads (rear)", action: "Replaced",
                                 atKm: 6500, cost: 18)
        svc2.bike = road; context.insert(svc2)
        let svc3 = ServiceRecord(date: daysAgo(10), componentName: "Drivetrain", action: "Cleaned",
                                 atKm: 8100, cost: 0, notes: "Deep clean + re-lube.")
        svc3.bike = road; context.insert(svc3)
        let svc4 = ServiceRecord(date: daysAgo(30), componentName: "Tubeless sealant", action: "Serviced",
                                 atKm: 2800, cost: 12, notes: "Topped up both tyres.")
        svc4.bike = gravel; context.insert(svc4)

        try? context.save()
    }

    private static func daysAgo(_ d: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -d, to: Date()) ?? Date()
    }

    private static func addComponent(_ ctx: ModelContext, _ bike: Bike, _ name: String, _ cat: String,
                                     at: Double, km: Double, days: Int = 0, installedDaysAgo: Int = 200) {
        let c = Component(name: name, category: cat, installedAtKm: at, lifespanKm: km, lifespanDays: days,
                          installedDate: daysAgo(installedDaysAgo))
        c.bike = bike
        ctx.insert(c)
    }
}
