import Foundation
import SwiftData

/// Bridges sensor figures into SwiftData. Upserts one `DayLog` per calendar
/// day so history accumulates beyond CoreMotion's ~7-day retention window.
enum HistoryStore {

    @MainActor
    static func upsert(_ samples: [DaySteps], goal: Int, fromSensor: Bool, context: ModelContext) {
        guard !samples.isEmpty else { return }
        let existing = (try? context.fetch(FetchDescriptor<DayLog>())) ?? []
        var byDay = Dictionary(existing.map { (Calendar.current.startOfDay(for: $0.day), $0) },
                               uniquingKeysWith: { a, _ in a })
        for s in samples {
            let key = Calendar.current.startOfDay(for: s.day)
            if let log = byDay[key] {
                log.steps = s.steps
                log.distanceMeters = s.distanceMeters
                log.flights = s.flights
                // Keep the goal that was in force; only set if this day is today
                // or the stored goal is unset.
                if Calendar.current.isDateInToday(key) || log.goal == 0 { log.goal = goal }
                log.fromSensor = fromSensor
            } else {
                let log = DayLog(day: key, steps: s.steps, distanceMeters: s.distanceMeters,
                                 flights: s.flights, goal: goal, fromSensor: fromSensor)
                context.insert(log)
                byDay[key] = log
            }
        }
        try? context.save()
    }

    /// Recompute and persist newly earned badges. Returns the freshly unlocked ones.
    @MainActor
    static func syncBadges(logs: [DayLog], context: ModelContext) -> [BadgeDef] {
        let earned = StepEngine.earnedBadgeIDs(logs: logs)
        let existing = (try? context.fetch(FetchDescriptor<Badge>())) ?? []
        let have = Set(existing.map(\.key))
        var newly: [BadgeDef] = []
        for id in earned where !have.contains(id) {
            if let def = BadgeCatalog.def(for: id) {
                context.insert(Badge(key: id, unlockedAt: Date()))
                newly.append(def)
            }
        }
        if !newly.isEmpty { try? context.save() }
        return newly
    }
}

/// Generates a plausible 30-day history so people on devices without a motion
/// sensor (iPad, Simulator) can explore every screen. Off by default; toggled
/// in Settings.
enum SampleData {
    @MainActor
    static func install(goal: Int, context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func next() -> Double {
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
            return Double(seed % 10_000) / 10_000.0
        }
        var samples: [DaySteps] = []
        for offset in 0...29 {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let weekday = cal.component(.weekday, from: d)
            let weekendDip = (weekday == 1 || weekday == 7) ? 0.78 : 1.0
            let base = 6_500.0 + next() * 9_000.0
            let steps = Int(base * weekendDip)
            let stride = 0.74    // meters per step
            samples.append(DaySteps(day: d, steps: steps,
                                    distanceMeters: Double(steps) * stride,
                                    flights: Int(next() * 14)))
        }
        upsert(samples, goal: goal, fromSensor: false, context: context)
    }

    @MainActor
    static func removeAll(context: ModelContext) {
        let logs = (try? context.fetch(FetchDescriptor<DayLog>())) ?? []
        for log in logs where !log.fromSensor { context.delete(log) }
        try? context.save()
    }
}
