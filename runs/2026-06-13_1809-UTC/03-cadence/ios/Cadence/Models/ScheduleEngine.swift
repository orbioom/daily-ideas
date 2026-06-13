import Foundation

enum OccurrenceStatus {
    case pending      // due today, not yet acted on
    case taken
    case skipped
    case missed       // a past day's slot with no log
}

struct DoseOccurrence: Identifiable {
    let id: String
    let med: Medication
    let slotDate: Date
    let minuteOfDay: Int
    let status: OccurrenceStatus
    let log: DoseLog?
}

/// Pure scheduling: turns medications + logs into concrete daily occurrences,
/// and rolls them up into adherence and streaks.
enum ScheduleEngine {
    private static var cal: Calendar { Calendar.current }

    static func minuteOfDay(_ date: Date) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func slotDate(on day: Date, minute: Int) -> Date {
        let start = cal.startOfDay(for: day)
        return cal.date(byAdding: .minute, value: minute, to: start) ?? start
    }

    /// Scheduled occurrences for a calendar day across all meds.
    static func occurrences(on day: Date, meds: [Medication], logs: [DoseLog],
                            now: Date = Date()) -> [DoseOccurrence] {
        let weekday = cal.component(.weekday, from: day)   // 1=Sun … 7=Sat
        let dayStart = cal.startOfDay(for: day)
        let isPastDay = dayStart < cal.startOfDay(for: now)
        var out: [DoseOccurrence] = []

        for med in meds where med.isActive && med.schedule != .asNeeded {
            // Don't generate slots before the med was added.
            if dayStart < cal.startOfDay(for: med.createdAt) { continue }
            guard med.occursOn(weekday: weekday) else { continue }
            for minute in med.times {
                let slot = slotDate(on: day, minute: minute)
                let match = logs.first { lg in
                    lg.medID == med.id &&
                    cal.isDate(lg.scheduledAt, inSameDayAs: day) &&
                    abs(minuteOfDay(lg.scheduledAt) - minute) < 1
                }
                let status: OccurrenceStatus
                if let match {
                    status = match.status == .taken ? .taken : .skipped
                } else if isPastDay {
                    status = .missed
                } else {
                    status = .pending
                }
                out.append(DoseOccurrence(
                    id: "\(med.id.uuidString)-\(Int(dayStart.timeIntervalSince1970))-\(minute)",
                    med: med, slotDate: slot, minuteOfDay: minute,
                    status: status, log: match))
            }
        }
        return out.sorted { $0.slotDate < $1.slotDate }
    }

    /// (taken, countable-total) for a day. Future pending slots aren't counted.
    static func dayAdherence(on day: Date, meds: [Medication], logs: [DoseLog],
                             now: Date = Date()) -> (taken: Int, total: Int)? {
        let occ = occurrences(on: day, meds: meds, logs: logs, now: now)
        let countable = occ.filter { o in
            switch o.status {
            case .taken, .skipped, .missed: return true
            case .pending: return o.slotDate <= now   // due time has passed
            }
        }
        guard !countable.isEmpty else { return nil }
        let taken = countable.filter { $0.status == .taken }.count
        return (taken, countable.count)
    }

    /// Adherence percent (0…1) over the last `days` days ending today.
    static func adherence(lastDays days: Int, meds: [Medication], logs: [DoseLog],
                          now: Date = Date()) -> Double? {
        var t = 0, n = 0
        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { continue }
            if let a = dayAdherence(on: day, meds: meds, logs: logs, now: now) {
                t += a.taken; n += a.total
            }
        }
        guard n > 0 else { return nil }
        return Double(t) / Double(n)
    }

    /// Consecutive fully-complete days ending at the most recent complete day.
    static func currentStreak(meds: [Medication], logs: [DoseLog], now: Date = Date()) -> Int {
        var streak = 0
        // Today only counts if already fully complete; otherwise it neither adds nor breaks.
        if let today = dayAdherence(on: now, meds: meds, logs: logs, now: now),
           today.total > 0, today.taken == today.total {
            streak += 1
        }
        var offset = 1
        while offset <= 400 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { break }
            if let a = dayAdherence(on: day, meds: meds, logs: logs, now: now) {
                if a.total > 0 && a.taken == a.total { streak += 1 } else { break }
            }
            offset += 1
        }
        return streak
    }

    /// Soonest still-pending occurrence today at/after `now`.
    static func nextDose(meds: [Medication], logs: [DoseLog], now: Date = Date()) -> DoseOccurrence? {
        occurrences(on: now, meds: meds, logs: logs, now: now)
            .first { $0.status == .pending && $0.slotDate >= now }
    }
}
