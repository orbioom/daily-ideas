import Foundation
import SwiftData

/// Seeds a reef tank with weeks of readings, a dosing log, and tasks.
enum SampleData {
    static func seed(into context: ModelContext) {
        let tank = Tank(name: "Living Room Reef", kind: .reef, volumeLitres: 220)
        tank.setupDate = Calendar.current.date(byAdding: .month, value: -14, to: Date()) ?? Date()
        tank.notes = "Mixed reef — SPS dominant up top, LPS on the sand bed."
        context.insert(tank)

        let cal = Calendar.current
        // 10 weekly test sessions with gentle drift
        let series: [(WaterParameter, Double, Double)] = [
            (.temperature, 26.0, 0.3), (.ph, 8.1, 0.06), (.salinity, 34.5, 0.3),
            (.alkalinity, 8.6, 0.5), (.calcium, 425, 12), (.magnesium, 1350, 18),
            (.nitrate, 6, 2.5), (.phosphate, 0.06, 0.02), (.ammonia, 0, 0)
        ]
        for week in 0..<10 {
            let date = cal.date(byAdding: .day, value: -(9 - week) * 7, to: Date()) ?? Date()
            for (p, base, jitter) in series {
                let wobble = sin(Double(week) * 0.9) * jitter
                let value = max(0, base + wobble)
                let r = Reading(parameter: p, value: value, date: date)
                r.tank = tank
                tank.readings.append(r)
                context.insert(r)
            }
        }

        let doses: [(String, Double, Int)] = [
            ("Alk (Part 1)", 12, 1), ("Calcium (Part 2)", 12, 1),
            ("Magnesium", 20, 4), ("Phyto", 5, 2), ("Alk (Part 1)", 12, 3)
        ]
        for (name, ml, daysAgo) in doses {
            let dose = DoseEntry(supplement: name, amountMl: ml,
                                 date: cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date())
            dose.tank = tank; tank.doses.append(dose); context.insert(dose)
        }

        let tasks: [(String, Int, Int)] = [
            ("Water change (10%)", 14, 3), ("Clean skimmer cup", 7, 1),
            ("Test full panel", 7, 6), ("Replace filter floss", 7, 8), ("Glass cleaning", 3, 0)
        ]
        for (title, interval, lastDaysAgo) in tasks {
            let t = CareTask(title: title, intervalDays: interval)
            t.lastDone = cal.date(byAdding: .day, value: -lastDaysAgo, to: Date())
            t.tank = tank; tank.tasks.append(t); context.insert(t)
        }
        try? context.save()
    }
}
