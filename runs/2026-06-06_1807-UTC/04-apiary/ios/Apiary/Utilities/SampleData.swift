import Foundation
import SwiftData

/// Seeds two apiaries with hives, inspections, treatments, and harvests.
enum SampleData {
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        func day(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: .now) ?? .now }
        let thisYear = cal.component(.year, from: .now)

        let home = Apiary(name: "Home Garden", location: "Back fence row", notes: "Morning sun, afternoon shade.")
        let orchard = Apiary(name: "Orchard Site", location: "Neighbor's apple orchard")
        context.insert(home); context.insert(orchard)

        // Hive 1 — strong, well-managed
        let h1 = Hive(name: "Amber", kind: .langstroth, status: .active, establishedDate: day(400),
                      queenYear: thisYear, apiary: home)
        h1.inspections = [
            Inspection(date: day(28), queenSeen: true, eggsSeen: true, queenCells: 0, brood: .high,
                       population: .high, stores: .high, temperament: .calm, space: .balanced,
                       mitesPer300: 2, weather: "Sunny 24°C", hive: h1),
            Inspection(date: day(10), queenSeen: true, eggsSeen: true, queenCells: 0, brood: .veryHigh,
                       population: .veryHigh, stores: .high, temperament: .calm, space: .crowded,
                       mitesPer300: 4, weather: "Warm, light breeze", notes: "Added a super.", hive: h1),
        ]
        h1.harvests = [Harvest(date: day(12), type: .honey, weightKg: 11.5, frames: 8, hive: h1)]
        context.insert(h1)

        // Hive 2 — swarm risk + mite alert
        let h2 = Hive(name: "Clover", kind: .langstroth, status: .active, establishedDate: day(300),
                      queenYear: thisYear - 1, apiary: home)
        h2.inspections = [
            Inspection(date: day(6), queenSeen: false, eggsSeen: true, queenCells: 3, brood: .high,
                       population: .veryHigh, stores: .medium, temperament: .defensive, space: .crowded,
                       mitesPer300: 11, weather: "Humid 27°C",
                       notes: "Three capped queen cells on the bottom bars — crowded.", hive: h2),
        ]
        h2.treatments = [
            Treatment(product: "Formic Pro", reason: "Varroa", startDate: day(2), durationDays: 14, hive: h2),
        ]
        context.insert(h2)

        // Hive 3 — queenless, needs attention
        let h3 = Hive(name: "Sage", kind: .topBar, status: .queenless, establishedDate: day(150),
                      queenYear: thisYear - 2, queenMarked: false, apiary: orchard)
        h3.inspections = [
            Inspection(date: day(20), queenSeen: false, eggsSeen: false, queenCells: 0, brood: .veryLow,
                       population: .low, stores: .low, temperament: .normal, space: .room,
                       mitesPer300: 1, notes: "No eggs, no queen seen. Possibly queenless.", hive: h3),
        ]
        context.insert(h3)

        // Hive 4 — established, last harvest
        let h4 = Hive(name: "Linden", kind: .warre, status: .active, establishedDate: day(220),
                      queenYear: thisYear, apiary: orchard)
        h4.inspections = [
            Inspection(date: day(15), queenSeen: true, eggsSeen: true, queenCells: 0, brood: .medium,
                       population: .high, stores: .high, temperament: .normal, space: .balanced,
                       mitesPer300: 5, hive: h4),
        ]
        h4.harvests = [
            Harvest(date: day(40), type: .honey, weightKg: 7.0, frames: 5, hive: h4),
            Harvest(date: day(40), type: .wax, weightKg: 0.4, hive: h4),
        ]
        h4.treatments = [
            Treatment(product: "Apivar", reason: "Varroa", startDate: day(60), durationDays: 42,
                      completed: true, hive: h4),
        ]
        context.insert(h4)

        try? context.save()
    }
}
