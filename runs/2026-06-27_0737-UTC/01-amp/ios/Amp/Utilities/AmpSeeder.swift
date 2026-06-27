import SwiftData
import Foundation

enum AmpSeeder {
    static func seed(context: ModelContext) {
        let descriptor = FetchDescriptor<Vehicle>()
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        let v1 = Vehicle(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023,
                         batteryKWh: 75, rangeKm: 576, colorHex: "#C0C0C0")
        let v2 = Vehicle(name: "Family Car", make: "Chevrolet", model: "Bolt EV", year: 2022,
                         batteryKWh: 65, rangeKm: 417, colorHex: "#4CAF50")
        context.insert(v1)
        context.insert(v2)

        let locations = [
            "Home", "Work Parking", "Target Store", "Whole Foods", "Tesla Supercharger – Downtown",
            "ChargePoint – Mall", "EVgo – Highway Rest Stop", "Blink – Hotel", "Home", "Work Parking"
        ]
        let chargerTypes: [ChargerType] = [.l2, .l2, .supercharger, .l2, .supercharger, .dcFast, .dcFast, .l2, .l1, .l2]
        let calendar = Calendar.current
        let now = Date()

        // 40 sessions for v1 over 6 months
        for i in 0..<40 {
            let daysAgo = Double(i) * 4.3 + Double.random(in: 0...2)
            let date = calendar.date(byAdding: .day, value: -Int(daysAgo), to: now) ?? now
            let kwh = Double.random(in: 15...68)
            let cType = chargerTypes[i % chargerTypes.count]
            let ratePerKWh = Double.random(in: 0.12...0.42)
            let cost = kwh * ratePerKWh
            let startSoC = Double.random(in: 10...40)
            let endSoC = min(startSoC + kwh / 0.75 * 100 / 100 * Double.random(in: 0.85...1.0), 95)
            let dur = kwh / Double.random(in: 6.5...22) * 60
            let s = ChargingSession(
                date: date, kwhAdded: kwh, cost: cost,
                startSoC: startSoC, endSoC: min(endSoC, 95),
                chargerType: cType,
                locationName: locations[i % locations.count],
                durationMinutes: dur,
                odometer: 15000 + Double(i) * 120,
                notes: i % 7 == 0 ? "Road trip stop" : "",
                vehicle: v1
            )
            context.insert(s)
        }

        // 15 sessions for v2
        for i in 0..<15 {
            let daysAgo = Double(i) * 10 + Double.random(in: 0...3)
            let date = calendar.date(byAdding: .day, value: -Int(daysAgo), to: now) ?? now
            let kwh = Double.random(in: 12...55)
            let cost = kwh * Double.random(in: 0.13...0.35)
            let s = ChargingSession(
                date: date, kwhAdded: kwh, cost: cost,
                startSoC: Double.random(in: 15...35),
                endSoC: Double.random(in: 75...95),
                chargerType: i % 4 == 0 ? .dcFast : .l2,
                locationName: locations[i % locations.count],
                durationMinutes: kwh / 10 * 60,
                odometer: 8000 + Double(i) * 80,
                notes: "",
                vehicle: v2
            )
            context.insert(s)
        }

        try? context.save()
    }
}
