import Foundation
import SwiftData

enum SeedData {
    static func seedSampleVehicle(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let v = Vehicle(name: "Daily Driver", make: "Toyota", model: "Corolla",
                        year: 2020, plate: "", odometerKm: 68_400, fuelType: .petrol)
        context.insert(v)

        // ~9 months of monthly full tanks, ~6.5 L/100km, climbing odometer.
        var odo = 60_000.0
        for m in stride(from: 9, through: 0, by: -1) {
            let date = cal.date(byAdding: .month, value: -m, to: today) ?? today
            odo += Double.random(in: 850...1050)
            let liters = (odo.truncatingRemainder(dividingBy: 100) > 0 ? 0 : 0) + Double.random(in: 42...50)
            let price = Double.random(in: 1.55...1.85)
            let f = FuelEntry(date: date, odometerKm: odo, liters: liters,
                              totalCost: liters * price, isFullTank: true)
            f.vehicle = v
            context.insert(f)
        }
        v.odometerKm = odo

        let s1 = ServiceRecord(date: cal.date(byAdding: .month, value: -4, to: today) ?? today,
                               odometerKm: odo - 4000, type: .oilChange, cost: 79,
                               notes: "Synthetic, new filter")
        let s2 = ServiceRecord(date: cal.date(byAdding: .month, value: -2, to: today) ?? today,
                               odometerKm: odo - 1500, type: .tires, cost: 480,
                               notes: "Set of 4 all-season")
        s1.vehicle = v; s2.vehicle = v
        context.insert(s1); context.insert(s2)

        let r1 = ServiceReminder(title: "Oil change", type: .oilChange,
                                 dueOdometerKm: odo + 200, repeatEveryKm: 10_000)
        let r2 = ServiceReminder(title: "Registration renewal", type: .registration,
                                 dueDate: cal.date(byAdding: .day, value: 40, to: today),
                                 repeatEveryMonths: 12)
        let r3 = ServiceReminder(title: "Tire rotation", type: .tires,
                                 dueOdometerKm: odo + 6000, repeatEveryKm: 10_000)
        r1.vehicle = v; r2.vehicle = v; r3.vehicle = v
        context.insert(r1); context.insert(r2); context.insert(r3)

        try? context.save()
    }
}
