import Foundation

/// A computed snapshot of the user's sleep state, derived from logs + settings.
/// Built off the main actor where needed; pure value type so it is cheap to pass.
struct SleepMetrics {
    let debt: Double
    let consistency: Int
    let avgDuration: Double
    let avgQuality: Double
    let suggestedBedtime: Date
    let windDownStart: Date
    let goalHours: Double
    let nightsLogged: Int

    static func make(
        logs: [SleepLog],
        settings: SleepSettings,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> SleepMetrics {
        let goal = settings.goalHours
        let chrono = settings.chronotype
        let windDown = chrono.windDownMinutes

        let bedtime = SleepEngine.suggestedBedtime(
            wakeTime: settings.anchorWakeTime,
            goalHours: goal,
            chronotype: chrono,
            windDownMinutes: windDown,
            includeWindDown: settings.includeWindDownInSuggestion,
            now: now,
            calendar: calendar
        )

        let windStart = settings.includeWindDownInSuggestion
            ? SleepEngine.windDownStart(bedtime: bedtime, windDownMinutes: windDown)
            : bedtime

        let recentCount = SleepEngine.nights(logs: logs, window: 14, now: now, calendar: calendar).count

        return SleepMetrics(
            debt: SleepEngine.sleepDebt(logs: logs, goalHours: goal, now: now, calendar: calendar),
            consistency: SleepEngine.consistencyScore(logs: logs, now: now, calendar: calendar),
            avgDuration: SleepEngine.averageDuration(logs: logs, now: now, calendar: calendar),
            avgQuality: SleepEngine.averageQuality(logs: logs, now: now, calendar: calendar),
            suggestedBedtime: bedtime,
            windDownStart: windStart,
            goalHours: goal,
            nightsLogged: recentCount
        )
    }

    /// Coaching headline based on current debt.
    var debtVerdict: (text: String, isGood: Bool) {
        switch debt {
        case ..<1: return ("You're well rested", true)
        case 1..<4: return ("A little catching up to do", true)
        case 4..<8: return ("Sleep debt is building", false)
        default: return ("You're carrying real sleep debt", false)
        }
    }

    var consistencyVerdict: String {
        switch consistency {
        case 85...100: return "Rock-steady rhythm"
        case 65..<85: return "Fairly consistent"
        case 40..<65: return "A bit scattered"
        default: return "Irregular — pick an anchor"
        }
    }
}
