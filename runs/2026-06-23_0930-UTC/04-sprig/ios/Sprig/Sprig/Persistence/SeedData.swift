import Foundation
import SwiftData

/// Seeds a realistic first-run dataset: two babies with 60+ events across
/// feeds, sleeps, diapers, and growth so every screen has life on first launch.
enum SeedData {

    /// A tiny deterministic RNG so the seeded data is stable across launches.
    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Baby>())) ?? []
        guard existing.isEmpty else { return }

        var rng = SplitMix64(seed: 0xBABE_F00D)
        let cal = Calendar.current
        let now = Date()

        // --- Primary baby: 70 days old, full history ---
        let avaBirth = cal.date(byAdding: .day, value: -70, to: now) ?? now
        let ava = Baby(name: "Ava", birthDate: avaBirth, colorHex: "E28E52")
        context.insert(ava)
        seedLogs(for: ava, daysBack: 14, now: now, rng: &rng, breastBias: 0.6)
        seedGrowth(for: ava, birth: avaBirth, now: now, startG: 3200, startCM: 50, rng: &rng)

        // --- Second baby: 18 days old, lighter history ---
        let leoBirth = cal.date(byAdding: .day, value: -18, to: now) ?? now
        let leo = Baby(name: "Leo", birthDate: leoBirth, colorHex: "5C86C4")
        context.insert(leo)
        seedLogs(for: leo, daysBack: 7, now: now, rng: &rng, breastBias: 0.3)
        seedGrowth(for: leo, birth: leoBirth, now: now, startG: 3400, startCM: 51, rng: &rng)

        try? context.save()
    }

    private static func seedLogs(for baby: Baby, daysBack: Int, now: Date,
                                 rng: inout SplitMix64, breastBias: Double) {
        let cal = Calendar.current
        for dayOffset in 0..<daysBack {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOffset,
                                          to: cal.startOfDay(for: now)) else { continue }

            // ~7 feeds spread across the day.
            let feedCount = 6 + Int(rng.next() % 3)
            for i in 0..<feedCount {
                let hour = Int(Double(i) / Double(max(1, feedCount)) * 24) + Int(rng.next() % 2)
                let minute = Int(rng.next() % 60)
                guard let date = cal.date(bySettingHour: min(hour, 23), minute: minute,
                                          second: 0, of: dayStart),
                      date <= now else { continue }
                let isBreast = Double(rng.next() % 100) / 100.0 < breastBias
                if isBreast {
                    let kinds: [FeedKind] = [.breastLeft, .breastRight, .breastBoth]
                    let kind = kinds[Int(rng.next() % UInt64(kinds.count))]
                    let dur = 600 + Int(rng.next() % 900) // 10–25 min
                    baby.feeds.append(FeedLog(date: date, kind: kind, durationSeconds: dur))
                } else {
                    let ml = 60 + Double(rng.next() % 90) // ~60–150 mL
                    baby.feeds.append(FeedLog(date: date, kind: .bottle, volumeML: ml))
                }
            }

            // ~5 sleep sessions.
            let sleepCount = 4 + Int(rng.next() % 2)
            for i in 0..<sleepCount {
                let hour = Int(Double(i) / Double(max(1, sleepCount)) * 22) + 1
                let minute = Int(rng.next() % 50)
                guard let start = cal.date(bySettingHour: min(hour, 23), minute: minute,
                                           second: 0, of: dayStart),
                      start <= now else { continue }
                let lengthMin = (i == 0 ? 240 : 60) + Int(rng.next() % 120)
                let end = start.addingTimeInterval(Double(lengthMin) * 60)
                baby.sleeps.append(SleepLog(start: start, end: min(end, now)))
            }

            // ~6 diapers.
            let diaperCount = 5 + Int(rng.next() % 3)
            for i in 0..<diaperCount {
                let hour = Int(Double(i) / Double(max(1, diaperCount)) * 24)
                let minute = Int(rng.next() % 60)
                guard let date = cal.date(bySettingHour: min(hour, 23), minute: minute,
                                          second: 0, of: dayStart),
                      date <= now else { continue }
                let roll = rng.next() % 100
                let kind: DiaperKind = roll < 55 ? .wet : (roll < 80 ? .dirty : .mixed)
                baby.diapers.append(DiaperLog(date: date, kind: kind))
            }
        }
    }

    private static func seedGrowth(for baby: Baby, birth: Date, now: Date,
                                   startG: Double, startCM: Double, rng: inout SplitMix64) {
        let cal = Calendar.current
        let totalDays = max(1, cal.dateComponents([.day], from: birth, to: now).day ?? 1)
        // A weekly-ish cadence of measurements.
        var day = 0
        var weight = startG
        var length = startCM
        while day <= totalDays {
            guard let date = cal.date(byAdding: .day, value: day, to: birth), date <= now else { break }
            // Newborns gain ~25–35 g/day; grow ~0.3 cm/week.
            baby.growth.append(GrowthEntry(date: date, weightGrams: weight, lengthCM: length))
            let gained = Double(day == 0 ? 0 : (160 + Int(rng.next() % 90))) // ~per week
            weight += gained
            length += day == 0 ? 0 : (0.4 + Double(rng.next() % 4) / 10.0)
            day += 7
        }
    }
}
