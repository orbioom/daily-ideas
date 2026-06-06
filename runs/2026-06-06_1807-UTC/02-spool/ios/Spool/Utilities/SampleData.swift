import Foundation
import SwiftData

/// Seeds spools, printers, and print jobs so the app opens with real content.
enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        func day(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: .now) ?? .now }

        let ender = Printer(name: "Ender 3 V3", model: "Creality", watts: 110, notes: "0.4 mm nozzle")
        let bambu = Printer(name: "Bambu P1S", model: "Bambu Lab", watts: 150, notes: "Enclosed, hardened nozzle")
        context.insert(ender); context.insert(bambu)

        let spools: [Spool] = [
            Spool(brand: "Polymaker", material: .pla, colorName: "Galaxy Black", colorHex: "2A2D3A",
                  netWeightG: 1000, remainingG: 240, pricePaid: 22.99, purchaseDate: day(40)),
            Spool(brand: "Prusament", material: .petg, colorName: "Orange", colorHex: "E07B39",
                  netWeightG: 1000, remainingG: 820, pricePaid: 29.99, purchaseDate: day(20)),
            Spool(brand: "Hatchbox", material: .pla, colorName: "Sky Blue", colorHex: "5AA9E6",
                  netWeightG: 1000, remainingG: 95, pricePaid: 19.99, purchaseDate: day(60)),
            Spool(brand: "Overture", material: .abs, colorName: "White", colorHex: "F2F3F6",
                  netWeightG: 1000, remainingG: 1000, pricePaid: 21.50, purchaseDate: day(3)),
            Spool(brand: "SUNLU", material: .tpu, colorName: "Red", colorHex: "C0392B",
                  netWeightG: 500, remainingG: 410, pricePaid: 24.99, purchaseDate: day(15)),
        ]
        spools.forEach { context.insert($0) }

        let jobs: [(String, Int, Double, Int, Bool, Spool, Printer)] = [
            ("Benchy", 0, 14, 62, true, spools[0], bambu),
            ("Phone stand", 1, 48, 180, true, spools[0], bambu),
            ("Drawer organizer x4", 2, 210, 540, true, spools[1], ender),
            ("Cable clips", 4, 12, 45, true, spools[2], ender),
            ("Failed bracket", 5, 30, 90, false, spools[2], ender),
            ("Gridfinity bins", 7, 165, 430, true, spools[0], bambu),
            ("Vase mode planter", 9, 88, 200, true, spools[1], bambu),
        ]
        for j in jobs {
            let job = PrintJob(name: j.0, date: day(j.1), gramsUsed: j.2, durationMinutes: j.3,
                               success: j.4, spool: j.5, printer: j.6)
            context.insert(job)
        }

        try? context.save()
    }
}
