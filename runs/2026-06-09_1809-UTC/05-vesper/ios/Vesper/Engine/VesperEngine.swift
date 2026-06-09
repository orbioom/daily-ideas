import Foundation

/// Pure, static logic over prayers, reading logs, and the devotion library. No
/// SwiftData, no UI. Every function guards empty inputs and divide-by-zero so
/// callers never crash, and the daily devotion is fully deterministic per day.
enum VesperEngine {

    // MARK: - Daily devotion

    /// A stable yyyy-MM-dd key for a date in the current calendar / time zone.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2000
        let m = c.month ?? 1
        let d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Deterministic, stable hash of a string (FNV-1a, 64-bit). We avoid
    /// `Hashable.hashValue` because that is randomized per process launch.
    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    /// The devotion of the day — deterministic for a given calendar day, so the
    /// same day always shows the same reading. Falls back to the first entry.
    static func devotion(for date: Date, calendar: Calendar = .current) -> Devotion {
        let library = DevotionLibrary.all
        guard !library.isEmpty else {
            // The library is a compile-time constant; this fallback exists only
            // to keep the signature non-optional and total.
            return Devotion(id: 0, reference: "Psalm 23:1",
                            verse: "Yahweh is my shepherd; I shall lack nothing.",
                            theme: .trust,
                            reflection: "Rest in being led today.")
        }
        let key = dayKey(for: date, calendar: calendar)
        let index = Int(stableHash(key) % UInt64(library.count))
        return library[index]
    }

    // MARK: - Prayer stats

    struct PrayerStats {
        let active: Int
        let answered: Int
        let archived: Int
        let total: Int
        let answeredRate: Double      // answered / (active + answered), 0…1
        let answeredThisMonth: Int
    }

    static func prayerStats(_ prayers: [Prayer], now: Date = .now) -> PrayerStats {
        let active = prayers.filter { $0.status == .praying }.count
        let answered = prayers.filter { $0.status == .answered }.count
        let archived = prayers.filter { $0.status == .archived }.count
        let denom = active + answered
        let rate = denom == 0 ? 0 : Double(answered) / Double(denom)
        let cal = Calendar.current
        let answeredThisMonth = prayers.filter {
            guard $0.status == .answered, let at = $0.answeredAt else { return false }
            return cal.isDate(at, equalTo: now, toGranularity: .month)
        }.count
        return PrayerStats(active: active, answered: answered, archived: archived,
                           total: prayers.count, answeredRate: rate,
                           answeredThisMonth: answeredThisMonth)
    }

    /// Count of active prayers per category, sorted high → low.
    struct CategoryCount: Identifiable {
        let id = UUID()
        let category: PrayerCategory
        let count: Int
    }

    static func categoryBreakdown(_ prayers: [Prayer]) -> [CategoryCount] {
        let grouped = Dictionary(grouping: prayers.filter { $0.status != .archived },
                                 by: { $0.category })
        return PrayerCategory.allCases.compactMap { cat in
            let n = grouped[cat]?.count ?? 0
            return n > 0 ? CategoryCount(category: cat, count: n) : nil
        }
        .sorted { $0.count > $1.count }
    }

    /// Active prayers sorted oldest-created first (longest-standing).
    static func longestStanding(_ prayers: [Prayer], limit: Int = 5) -> [Prayer] {
        prayers.filter { $0.status == .praying }
            .sorted { $0.createdAt < $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }

    /// Active prayers with no activity in `days` or more, oldest activity first.
    static func needingAttention(_ prayers: [Prayer], days: Int = 14, limit: Int = 5) -> [Prayer] {
        prayers.filter { $0.status == .praying && $0.daysSinceActivity >= days }
            .sorted { $0.lastActivity < $1.lastActivity }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Activity & streaks

    /// The set of distinct calendar days on which any activity happened:
    /// a prayer was created, a prayer update was added, or a devotion was read.
    static func activityDays(_ prayers: [Prayer], _ logs: [ReadingLog],
                             calendar: Calendar = .current) -> Set<Date> {
        var days = Set<Date>()
        for p in prayers {
            days.insert(calendar.startOfDay(for: p.createdAt))
            for u in p.updates { days.insert(calendar.startOfDay(for: u.date)) }
        }
        for l in logs {
            days.insert(calendar.startOfDay(for: l.date))
        }
        return days
    }

    /// Consecutive-day streak ending today (or yesterday if today is empty).
    static func currentStreak(_ prayers: [Prayer], _ logs: [ReadingLog],
                              now: Date = .now, calendar: Calendar = .current) -> Int {
        let days = activityDays(prayers, logs, calendar: calendar)
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        // Allow the streak to count from today, or from yesterday if today is blank.
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func readingsThisMonth(_ logs: [ReadingLog], now: Date = .now) -> Int {
        let cal = Calendar.current
        return logs.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    /// Distinct devotions read (by id) over all time.
    static func devotionsReadTotal(_ logs: [ReadingLog]) -> Int {
        Set(logs.map(\.devotionID)).count
    }

    static func readingHistory(_ logs: [ReadingLog], devotionID: Int) -> [ReadingLog] {
        logs.filter { $0.devotionID == devotionID }.sorted { $0.date > $1.date }
    }

    // MARK: - Charts series

    struct MonthActivity: Identifiable {
        let id = UUID()
        let month: Date        // first day of the month
        let added: Int         // prayers created that month
        let answered: Int      // prayers answered that month
        let readings: Int      // reading logs that month
    }

    /// One point per month over the last `months` months (oldest → newest).
    static func monthlyActivity(_ prayers: [Prayer], _ logs: [ReadingLog],
                                months: Int = 6, now: Date = .now) -> [MonthActivity] {
        let cal = Calendar.current
        guard let thisMonthStart = cal.dateInterval(of: .month, for: now)?.start else { return [] }
        var out: [MonthActivity] = []
        for back in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = cal.date(byAdding: .month, value: -back, to: thisMonthStart) else { continue }
            let added = prayers.filter { cal.isDate($0.createdAt, equalTo: monthStart, toGranularity: .month) }.count
            let answered = prayers.filter {
                guard let at = $0.answeredAt else { return false }
                return cal.isDate(at, equalTo: monthStart, toGranularity: .month)
            }.count
            let readings = logs.filter { cal.isDate($0.date, equalTo: monthStart, toGranularity: .month) }.count
            out.append(MonthActivity(month: monthStart, added: added, answered: answered, readings: readings))
        }
        return out
    }
}
