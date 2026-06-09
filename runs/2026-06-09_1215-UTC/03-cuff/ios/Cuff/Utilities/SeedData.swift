import Foundation
import SwiftData

/// Seeds a realistic set of readings on first launch so Overview, Trends, and
/// Report all look alive for a brand-new user. Guarded so it runs exactly once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<VitalEntry>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date.now

        // Deterministic pseudo-random so the seed reads the same every run.
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func rnd() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double((seed >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
        }
        func jitter(_ base: Int, _ spread: Int) -> Int {
            base + Int((rnd() * 2 - 1) * Double(spread))
        }

        func at(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let base = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        // ~50 BP readings over ~6 weeks: morning + evening pairs, gently trending
        // down, spread across categories.
        for day in stride(from: 41, through: 0, by: -1) {
            let progress = Double(41 - day) / 41.0   // 0 → 1 over the window
            // Morning reading (most days).
            if rnd() > 0.12 {
                let sys = jitter(Int(140 - progress * 18), 7)
                let dia = jitter(Int(90 - progress * 10), 5)
                context.insert(VitalEntry(
                    date: at(daysAgo: day, hour: 7, minute: jitter(20, 15)),
                    kind: .bloodPressure,
                    systolic: sys, diastolic: dia,
                    pulse: jitter(72, 8),
                    tag: .morning, arm: .left))
            }
            // Evening reading (slightly higher, fewer days).
            if rnd() > 0.30 {
                let sys = jitter(Int(144 - progress * 16), 8)
                let dia = jitter(Int(92 - progress * 9), 6)
                context.insert(VitalEntry(
                    date: at(daysAgo: day, hour: 21, minute: jitter(10, 20)),
                    kind: .bloodPressure,
                    systolic: sys, diastolic: dia,
                    pulse: jitter(76, 9),
                    tag: .evening, arm: .left))
            }
        }

        // ~15 weight readings (kg canonical), trending slightly down.
        for i in 0..<15 {
            let day = 40 - i * 2
            let kg = 84.5 - Double(i) * 0.18 + (rnd() - 0.5) * 0.6
            context.insert(VitalEntry(
                date: at(daysAgo: max(0, day), hour: 7, minute: 5),
                kind: .weight,
                value: kg,
                tag: .morning))
        }

        // ~10 glucose readings (mg/dL canonical).
        for i in 0..<10 {
            let day = 38 - i * 3
            let mgdl = 98 + (rnd() - 0.4) * 24
            context.insert(VitalEntry(
                date: at(daysAgo: max(0, day), hour: 8, minute: 0),
                kind: .glucose,
                value: mgdl,
                tag: .morning))
        }

        // A few SpO₂ readings.
        for i in 0..<5 {
            let day = 30 - i * 5
            let spo2 = 97 + rnd() * 2
            context.insert(VitalEntry(
                date: at(daysAgo: max(0, day), hour: 20, minute: 30),
                kind: .spo2,
                value: spo2.rounded(),
                tag: .evening))
        }

        try? context.save()
    }
}
