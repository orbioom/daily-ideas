import Foundation
import SwiftData

/// Seeds ~120 realistic readings across the last ~21 days, behind the "didSeed" flag.
enum SeedData {

    /// A deterministic-ish slot template for a day: (hour, minute, context).
    private struct Slot {
        let hour: Int
        let minute: Int
        let context: ReadingContext
        let withCarbs: Bool
        let withInsulin: Bool
    }

    private static let daySlots: [Slot] = [
        Slot(hour: 7,  minute: 15, context: .fasting,    withCarbs: false, withInsulin: false),
        Slot(hour: 8,  minute: 0,  context: .beforeMeal, withCarbs: true,  withInsulin: true),
        Slot(hour: 10, minute: 30, context: .afterMeal,  withCarbs: false, withInsulin: false),
        Slot(hour: 12, minute: 45, context: .beforeMeal, withCarbs: true,  withInsulin: true),
        Slot(hour: 14, minute: 30, context: .afterMeal,  withCarbs: false, withInsulin: false),
        Slot(hour: 17, minute: 0,  context: .exercise,   withCarbs: false, withInsulin: false),
        Slot(hour: 18, minute: 45, context: .beforeMeal, withCarbs: true,  withInsulin: true),
        Slot(hour: 21, minute: 0,  context: .afterMeal,  withCarbs: false, withInsulin: false),
        Slot(hour: 22, minute: 30, context: .bedtime,    withCarbs: false, withInsulin: false)
    ]

    private static let notes = [
        "", "", "", "Felt a little shaky", "Big lunch today", "After a walk",
        "Stressful day at work", "Slept well", "", "Skipped breakfast", ""
    ]

    static func seedIfNeeded(context ctx: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // A simple linear-congruential generator for reproducible pseudo-randomness.
        var seed: UInt64 = 0x9E3779B97F4A7C15

        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double((seed >> 11) & 0xFFFFFFFFFFFFF) / Double(1 << 52)  // 0..<1
        }

        for dayOffset in 0..<21 {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            // Some variety: most days log 5–8 readings.
            let slotCount = 5 + Int(next() * Double(daySlots.count - 4))
            let clampedCount = min(max(slotCount, 5), daySlots.count)
            for i in 0..<clampedCount {
                guard i < daySlots.count else { break }
                let slot = daySlots[i]
                guard let date = cal.date(bySettingHour: slot.hour,
                                          minute: slot.minute,
                                          second: 0,
                                          of: dayStart) else { continue }

                // Base value depends on context; mostly 80–190 with occasional excursions.
                let base = baseValue(for: slot.context)
                let jitter = (next() - 0.5) * 60      // ±30
                var value = base + jitter

                // Occasional low or high spikes (~8% each).
                let roll = next()
                if roll < 0.06 { value = 52 + next() * 16 }        // a low
                else if roll > 0.92 { value = 230 + next() * 90 }  // a high

                value = min(max(value, 40), 360).rounded()

                let carbs: Double? = slot.withCarbs ? Double(25 + Int(next() * 60)) : nil
                let insulin: Double? = slot.withInsulin ? (2 + (next() * 8)).rounded() : nil
                let note = notes[Int(next() * Double(notes.count)) % notes.count]

                let reading = Reading(valueMgdl: value,
                                      context: slot.context,
                                      carbs: carbs,
                                      insulinUnits: insulin,
                                      note: note,
                                      date: date)
                ctx.insert(reading)
            }
        }

        try? ctx.save()
        didSeed = true
    }

    private static func baseValue(for context: ReadingContext) -> Double {
        switch context {
        case .fasting: return 105
        case .beforeMeal: return 115
        case .afterMeal: return 155
        case .bedtime: return 125
        case .exercise: return 100
        case .random: return 130
        }
    }

    /// Wipe all readings.
    static func clearAll(context ctx: ModelContext) {
        let descriptor = FetchDescriptor<Reading>()
        if let all = try? ctx.fetch(descriptor) {
            for r in all { ctx.delete(r) }
            try? ctx.save()
        }
    }
}
