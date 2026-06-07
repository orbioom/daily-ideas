import Foundation
import SwiftData

/// Seeds a few medications with 30 days of dose history and refills.
enum SampleData {

    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        init(_ s: UInt64) { state = s == 0 ? 0xABCDEF12345 : s }
        mutating func next() -> UInt64 {
            state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
        }
    }

    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        var rng = Seeded(99)

        let meds: [Medication] = [
            Medication(name: "Levothyroxine", strength: "75 mcg", form: "Tablet",
                       doseTimes: [420], weekdays: [], unitsPerDose: 1, quantityOnHand: 22,
                       refillThresholdDays: 7, colorHex: 0x5EB7F0, notes: "Take on an empty stomach."),
            Medication(name: "Metformin", strength: "500 mg", form: "Tablet",
                       doseTimes: [480, 1140], weekdays: [], unitsPerDose: 1, quantityOnHand: 48,
                       refillThresholdDays: 10, colorHex: 0x86C79A, notes: "With meals."),
            Medication(name: "Vitamin D", strength: "2000 IU", form: "Capsule",
                       doseTimes: [540], weekdays: [2], unitsPerDose: 1, quantityOnHand: 9,
                       refillThresholdDays: 14, colorHex: 0xE0A35E, notes: "Mondays."),
            Medication(name: "Atorvastatin", strength: "20 mg", form: "Tablet",
                       doseTimes: [1320], weekdays: [], unitsPerDose: 1, quantityOnHand: 64,
                       refillThresholdDays: 7, colorHex: 0xC78FD6)
        ]
        for m in meds { context.insert(m) }

        // 30 days of history
        let now = Date()
        for med in meds {
            for offset in 1...30 {
                guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { continue }
                guard med.isScheduled(on: day, calendar: cal) else { continue }
                for minutes in med.sortedDoseTimes {
                    let at = cal.date(byAdding: .minute, value: minutes, to: cal.startOfDay(for: day)) ?? day
                    // ~88% taken, occasional skip
                    let roll = rng.next() % 100
                    let status = roll < 88 ? "taken" : (roll < 94 ? "skipped" : nil)
                    if let status {
                        let log = DoseLog(scheduledAt: at, status: status, medication: med)
                        log.loggedAt = at.addingTimeInterval(Double(rng.next() % 3600))
                        context.insert(log)
                    }
                }
            }
        }

        // Refills
        let r1 = Refill(date: cal.date(byAdding: .day, value: -20, to: now) ?? now,
                        quantity: 30, pharmacy: "Corner Pharmacy", cost: 12, medication: meds[0])
        context.insert(r1)
        let r2 = Refill(date: cal.date(byAdding: .day, value: -12, to: now) ?? now,
                        quantity: 60, pharmacy: "Mail Order", cost: 8, medication: meds[1])
        context.insert(r2)
        let r3 = Refill(date: cal.date(byAdding: .day, value: -40, to: now) ?? now,
                        quantity: 90, pharmacy: "Corner Pharmacy", cost: 15, medication: meds[3])
        context.insert(r3)

        try? context.save()
    }
}
