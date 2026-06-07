import Foundation

/// Builds daily dose schedules, matches them to logs, and computes supply and
/// adherence figures.
enum DoseEngine {

    /// One scheduled dose slot for a given day.
    struct Slot: Identifiable {
        let id: String          // medID + scheduled time key
        let medication: Medication
        let scheduledAt: Date
        let minutesOfDay: Int
        var log: DoseLog?       // nil = not yet acted on
        var status: String { log?.status ?? "pending" }
        var taken: Bool { log?.status == "taken" }
        var skipped: Bool { log?.status == "skipped" }
    }

    static func minutesToTime(_ minutes: Int, on day: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    static func formatMinutes(_ minutes: Int) -> String {
        let h = (minutes / 60) % 24, m = minutes % 60
        var comps = DateComponents(); comps.hour = h; comps.minute = m
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    /// All dose slots for `day` across the given medications, matched to any logs.
    static func slots(for medications: [Medication], on day: Date,
                      logs: [DoseLog], calendar: Calendar = .current) -> [Slot] {
        let dayStart = calendar.startOfDay(for: day)
        // Index logs by (medID, scheduledAt rounded to minute)
        var logIndex: [String: DoseLog] = [:]
        for log in logs {
            guard let medID = log.medication?.id,
                  calendar.isDate(log.scheduledAt, inSameDayAs: day) else { continue }
            let key = slotKey(medID: medID, scheduledAt: log.scheduledAt, calendar: calendar)
            logIndex[key] = log
        }
        var result: [Slot] = []
        for med in medications where med.isScheduled(on: day, calendar: calendar) {
            for minutes in med.sortedDoseTimes {
                let at = calendar.date(byAdding: .minute, value: minutes, to: dayStart) ?? dayStart
                let key = slotKey(medID: med.id, scheduledAt: at, calendar: calendar)
                result.append(Slot(id: key, medication: med, scheduledAt: at,
                                   minutesOfDay: minutes, log: logIndex[key]))
            }
        }
        return result.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    static func slotKey(medID: UUID, scheduledAt: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledAt)
        return "\(medID.uuidString)-\(comps.year ?? 0)\(comps.month ?? 0)\(comps.day ?? 0)-\(comps.hour ?? 0):\(comps.minute ?? 0)"
    }

    // MARK: - Supply

    /// Projected run-out date from current supply and average consumption.
    static func runOutDate(for med: Medication) -> Date? {
        guard med.dailyConsumption > 0, med.quantityOnHand > 0 else { return nil }
        let days = Int(med.daysOfSupply.rounded(.down))
        return Calendar.current.date(byAdding: .day, value: days, to: Date())
    }

    /// Date at which a refill should be ordered (run-out minus threshold).
    static func refillByDate(for med: Medication) -> Date? {
        guard let runOut = runOutDate(for: med) else { return nil }
        return Calendar.current.date(byAdding: .day, value: -med.refillThresholdDays, to: runOut)
    }

    static func needsRefillSoon(_ med: Medication) -> Bool {
        guard med.dailyConsumption > 0 else { return false }
        return med.daysOfSupply <= Double(med.refillThresholdDays)
    }

    // MARK: - Adherence

    /// Adherence over the trailing `days`: taken ÷ scheduled (skipped + missed count against).
    static func adherence(for medications: [Medication], logs: [DoseLog],
                          trailingDays days: Int, calendar: Calendar = .current) -> Double {
        let (taken, scheduled) = adherenceCounts(for: medications, logs: logs, trailingDays: days, calendar: calendar)
        return scheduled > 0 ? Double(taken) / Double(scheduled) : 0
    }

    /// Returns (taken, scheduled) counts over the window, counting only days that
    /// have already fully passed plus today up to now.
    static func adherenceCounts(for medications: [Medication], logs: [DoseLog],
                                trailingDays days: Int, calendar: Calendar = .current) -> (Int, Int) {
        let now = Date()
        var taken = 0, scheduled = 0
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let daySlots = slots(for: medications, on: day, logs: logs, calendar: calendar)
            for slot in daySlots where slot.scheduledAt <= now {
                scheduled += 1
                if slot.taken { taken += 1 }
            }
        }
        return (taken, scheduled)
    }

    /// Per-day adherence fraction for the last `days` (oldest first) for a chart.
    static func dailyAdherence(for medications: [Medication], logs: [DoseLog],
                               days: Int, calendar: Calendar = .current) -> [Double] {
        let now = Date()
        var out: [Double] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { out.append(0); continue }
            let daySlots = slots(for: medications, on: day, logs: logs, calendar: calendar)
                .filter { $0.scheduledAt <= now }
            if daySlots.isEmpty { out.append(-1); continue }   // -1 = no doses scheduled
            let taken = daySlots.filter { $0.taken }.count
            out.append(Double(taken) / Double(daySlots.count))
        }
        return out
    }

    static let forms = ["Tablet", "Capsule", "Liquid", "Drop", "Injection", "Unit"]
    static let colors: [UInt32] = [0x5EB7F0, 0x86C79A, 0xE0A35E, 0xC78FD6, 0xE08A78, 0x6FB3A8, 0xB0B6C8]
    static let weekdayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}
