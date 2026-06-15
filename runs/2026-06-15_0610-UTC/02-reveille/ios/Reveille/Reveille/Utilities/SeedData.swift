import Foundation
import SwiftData

/// Seeds a handful of sample alarms and ~55 past WakeLogs spread over five weeks so the
/// Alarms list and the Stats charts are rich on first launch. Deterministic via SplitMix64.
/// Gated behind the `didSeed` flag.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertSampleAlarms(context: context)
        insertSampleWakeLogs(context: context)
        didSeed = true
    }

    /// Insert several realistic sample alarms (weekday wake, weekend lie-in, nap, etc.).
    static func insertSampleAlarms(context: ModelContext) {
        let samples: [Alarm] = [
            Alarm(hour: 6, minute: 30, repeatDays: [2, 3, 4, 5, 6],
                  label: "Workday wake-up", soundName: "chime",
                  missionType: .math, missionDifficulty: .medium, missionReps: 3,
                  snoozeEnabled: true, snoozeMinutes: 9, maxSnoozes: 2, volumeRampSeconds: 20),
            Alarm(hour: 8, minute: 0, repeatDays: [1, 7],
                  label: "Weekend gentle start", soundName: "birdsong",
                  missionType: .none, missionDifficulty: .easy, missionReps: 1,
                  snoozeEnabled: true, snoozeMinutes: 12, maxSnoozes: 3, volumeRampSeconds: 45),
            Alarm(hour: 5, minute: 45, repeatDays: [],
                  label: "Early flight", soundName: "beep",
                  missionType: .shake, missionDifficulty: .hard, missionReps: 1,
                  snoozeEnabled: false, snoozeMinutes: 5, maxSnoozes: 0, volumeRampSeconds: 5),
            Alarm(hour: 22, minute: 30, repeatDays: [2, 3, 4, 5],
                  label: "Wind-down reminder", soundName: "marimba",
                  missionType: .typing, missionDifficulty: .easy, missionReps: 1,
                  snoozeEnabled: true, snoozeMinutes: 10, maxSnoozes: 1, volumeRampSeconds: 30,
                  isEnabled: false)
        ]
        for alarm in samples { context.insert(alarm) }
        try? context.save()
    }

    /// Insert ~55 WakeLogs over the last ~38 days. Times-to-dismiss trend downward (you wake
    /// faster over time); snoozes taper off; wake times cluster around 6:40–7:10.
    static func insertSampleWakeLogs(context: ModelContext) {
        var rng = SplitMix64(seed: 0x5EEDF00D)
        let now = Date()
        let cal = Calendar.current
        let missions: [MissionType] = [.math, .shake, .memory, .tap, .typing, .none]

        for i in 0..<55 {
            let dayOffset = i * 38 / 55  // 0...~37, mostly one per day
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            // Wake clock-time clusters ~6:45 ± a little.
            let baseHour = 6 + rng.int(2)            // 6 or 7
            let baseMinute = 30 + rng.int(40)        // 30...69
            let hour = baseMinute >= 60 ? baseHour + 1 : baseHour
            let minute = baseMinute % 60
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            guard let fired = cal.date(from: comps) else { continue }

            // Improvement: more recent days dismiss faster.
            let skill = max(0, 37 - dayOffset)               // 0...37 (higher = more recent)
            let baseSeconds = max(20, 160 - skill * 3)        // ~160s long ago → ~30s recent
            let noise = rng.int(80) - 30
            let seconds = max(10, baseSeconds + noise)

            // Snoozes taper as you improve.
            let snoozeChance = max(0, 60 - skill)             // 0...60
            let snoozeCount = rng.int(100) < snoozeChance ? rng.int(in: 1...3) : 0

            let dismissed = fired.addingTimeInterval(Double(seconds))
            let mission = missions[rng.int(missions.count)]

            let log = WakeLog(alarmLabel: rng.int(3) == 0 ? "Weekend gentle start" : "Workday wake-up",
                              firedAt: fired,
                              dismissedAt: dismissed,
                              snoozeCount: snoozeCount,
                              missionType: mission)
            context.insert(log)
        }
        try? context.save()
    }

    /// Delete all WakeLogs (used by Settings "reset stats").
    static func clearWakeLogs(context: ModelContext) {
        if let logs = try? context.fetch(FetchDescriptor<WakeLog>()) {
            for l in logs { context.delete(l) }
        }
        try? context.save()
    }

    /// Delete everything Reveille owns (alarms + logs).
    static func clearAll(context: ModelContext) {
        if let alarms = try? context.fetch(FetchDescriptor<Alarm>()) {
            for a in alarms { context.delete(a) }
        }
        clearWakeLogs(context: context)
    }
}
