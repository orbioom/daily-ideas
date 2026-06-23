import Foundation
import SwiftData

/// Seeds realistic sample content on first launch so the app never feels empty.
enum SampleData {

    /// Default wind-down routine steps.
    static func defaultWindDown() -> [WindDownItem] {
        [
            WindDownItem(title: "Dim the lights", detail: "Drop overhead lights; switch to warm lamps.", symbol: "lightbulb.min.fill", order: 0),
            WindDownItem(title: "Screens away", detail: "Put the phone on the charger across the room.", symbol: "iphone.slash", order: 1),
            WindDownItem(title: "Set tomorrow's alarm", detail: "Confirm your wake time so the mind can let go.", symbol: "alarm.fill", order: 2),
            WindDownItem(title: "Warm shower or wash", detail: "A warm rinse cues the body to cool and drift.", symbol: "shower.fill", order: 3),
            WindDownItem(title: "Read a few pages", detail: "Paper, not pixels. Fiction is best.", symbol: "book.fill", order: 4),
            WindDownItem(title: "Slow breathing", detail: "Five rounds of 4-7-8 to settle the nervous system.", symbol: "wind", order: 5),
            WindDownItem(title: "Cool the room", detail: "Aim for around 18°C / 65°F.", symbol: "thermometer.snowflake", order: 6)
        ]
    }

    /// Generate 50+ nights of plausible sleep history ending yesterday.
    static func sampleLogs(now: Date = .now, calendar: Calendar = .current) -> [SleepLog] {
        var rng = SystemSeededGenerator(seed: 42)
        var logs: [SleepLog] = []
        let tags = ["caffeine", "screen", "exercise", "alcohol", "stress", "nap", "travel"]

        // 56 nights of history.
        for offset in 1...56 {
            guard let night = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else { continue }

            // Base bedtime ~23:10 with weekend drift and noise.
            let weekday = calendar.component(.weekday, from: night)
            let isWeekend = (weekday == 1 || weekday == 7)
            let bedBaseMin = isWeekend ? 24 * 60 + 10 : 23 * 60 + 10   // minutes from prev midnight
            let bedJitter = Int(rng.nextDouble() * 70) - 25
            let bedMinutes = bedBaseMin + bedJitter

            // Sleep length target ~7.6h with noise; weekends a touch longer.
            let baseHours = (isWeekend ? 8.1 : 7.4) + (rng.nextDouble() - 0.5) * 1.6
            let durationHours = max(4.5, min(9.8, baseHours))

            // Compose actual instants. Bedtime is on the *previous* calendar day.
            let prevDay = calendar.date(byAdding: .day, value: -1, to: night) ?? night
            let bedHour = (bedMinutes / 60) % 24
            let bedMin = bedMinutes % 60
            let crossesMidnight = bedMinutes >= 24 * 60
            let bedDay = crossesMidnight ? night : prevDay
            let bedTime = calendar.date(bySettingHour: bedHour, minute: bedMin, second: 0, of: bedDay) ?? night
            let wakeTime = bedTime.addingTimeInterval(durationHours * 3600)

            let quality = qualityFor(durationHours: durationHours, rng: &rng)
            let awakenings = Int(rng.nextDouble() * 3)

            var chosenTags: [String] = []
            if rng.nextDouble() < 0.45 { chosenTags.append(tags[Int(rng.nextDouble() * Double(tags.count)) % tags.count]) }
            if rng.nextDouble() < 0.2 { chosenTags.append(tags[Int(rng.nextDouble() * Double(tags.count)) % tags.count]) }
            chosenTags = Array(Set(chosenTags))

            logs.append(
                SleepLog(
                    night: night,
                    bedTime: bedTime,
                    wakeTime: wakeTime,
                    quality: quality,
                    awakenings: awakenings,
                    note: "",
                    tags: chosenTags
                )
            )
        }
        return logs
    }

    private static func qualityFor(durationHours: Double, rng: inout SystemSeededGenerator) -> Int {
        let base: Int
        switch durationHours {
        case ..<6: base = 2
        case 6..<7: base = 3
        case 7..<8.5: base = 4
        default: base = 4
        }
        let wobble = Int(rng.nextDouble() * 2) - 1
        return max(1, min(5, base + wobble))
    }
}

/// Tiny deterministic PRNG so sample data is stable across launches/devices.
struct SystemSeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 2_862_933_555_777_941_757 &+ 3_037_000_493 }
    mutating func nextDouble() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1_000_000) / 1_000_000.0
    }
}
