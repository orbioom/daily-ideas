import Foundation

/// How a single week cell relates to "now".
enum WeekPhase {
    case past
    case current
    case future
}

/// A computed life statistic bundle for the Perspective screen. Pure value type.
struct LifeStats {
    let weeksLived: Int
    let totalWeeks: Int
    let weeksRemaining: Int
    let daysLived: Int
    let monthsLived: Int
    let years: Int
    let months: Int
    let days: Int
    /// Fraction of expected life lived, clamped 0...1.
    let fractionLived: Double
    /// Approximate summers (Junes) remaining until end of expected span.
    let summersRemaining: Int

    var percentLived: Double { fractionLived * 100 }
}

/// The substantive, calendar-safe core. All date math goes through `Calendar`/`DateComponents`
/// so it is leap-year and month-length correct. No fixed 365/30 approximations on user paths.
struct SpanEngine {

    /// Weeks per row in the life calendar (one row = one year-ish band of 52 weeks).
    static let weeksPerYear = 52

    static let minExpectancy = 40
    static let maxExpectancy = 120

    /// Keep life expectancy in a sane, non-degenerate range.
    static func clampExpectancy(_ years: Int) -> Int {
        min(max(years, minExpectancy), maxExpectancy)
    }

    let birthDate: Date
    let lifeExpectancyYears: Int
    let weekStartsMonday: Bool
    private let calendar: Calendar

    init(birthDate: Date, lifeExpectancyYears: Int, weekStartsMonday: Bool) {
        self.birthDate = birthDate
        self.lifeExpectancyYears = SpanEngine.clampExpectancy(lifeExpectancyYears)
        self.weekStartsMonday = weekStartsMonday
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = weekStartsMonday ? 2 : 1
        self.calendar = cal
    }

    /// Convenience initializer from a stored profile.
    init(profile: LifeProfile) {
        self.init(birthDate: profile.birthDate,
                  lifeExpectancyYears: profile.lifeExpectancyYears,
                  weekStartsMonday: profile.weekStartsMonday)
    }

    /// Total dots in the grid.
    var totalWeeks: Int { lifeExpectancyYears * SpanEngine.weeksPerYear }

    /// Number of rows in the grid (one per year of expected life).
    var rows: Int { lifeExpectancyYears }

    /// The start of the birth week, normalized to the chosen first weekday & midnight.
    var birthWeekStart: Date {
        startOfWeek(for: birthDate)
    }

    /// Start-of-week (midnight, chosen firstWeekday) for any date.
    func startOfWeek(for date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    /// Full weeks elapsed from the birth week to the given date's week.
    /// Negative if `date` precedes birth (handled gracefully by callers).
    func weekIndex(for date: Date) -> Int {
        let from = birthWeekStart
        let to = startOfWeek(for: date)
        let weeks = calendar.dateComponents([.weekOfYear], from: from, to: to).weekOfYear ?? 0
        return weeks
    }

    /// Clamp a raw week index into the valid grid range, or nil if outside the span entirely.
    func gridIndex(for date: Date) -> Int? {
        let idx = weekIndex(for: date)
        guard idx >= 0 && idx < totalWeeks else { return nil }
        return idx
    }

    /// The week index for "now", clamped to [0, totalWeeks-1] for display safety.
    func currentWeekIndex(now: Date = Date()) -> Int {
        let idx = weekIndex(for: now)
        return min(max(idx, 0), max(totalWeeks - 1, 0))
    }

    /// Phase of a given grid cell relative to now.
    func phase(of index: Int, now: Date = Date()) -> WeekPhase {
        let current = weekIndex(for: now)
        if index < current { return .past }
        if index == current { return .current }
        return .future
    }

    /// The date range [start, nextWeekStart) covered by a grid cell.
    func dateRange(forWeek index: Int) -> (start: Date, end: Date) {
        let start = calendar.date(byAdding: .weekOfYear, value: index, to: birthWeekStart) ?? birthWeekStart
        let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
        return (start, end)
    }

    /// Age (years/months/days) at the start of a given week.
    func ageComponents(atWeek index: Int) -> DateComponents {
        let (start, _) = dateRange(forWeek: index)
        let clampedStart = max(start, birthDate)
        return calendar.dateComponents([.year, .month, .day], from: birthDate, to: clampedStart)
    }

    // MARK: - Life statistics

    /// Precise life statistics as of `now`. Guards against future birth dates and div-by-zero.
    func stats(now: Date = Date()) -> LifeStats {
        let total = max(totalWeeks, 1)

        // If birth is in the future, everything reads as zero progress.
        let bornInFuture = now < birthDate
        let effectiveNow = bornInFuture ? birthDate : now

        let livedWeeksRaw = weekIndex(for: effectiveNow)
        let weeksLived = min(max(livedWeeksRaw, 0), total)
        let weeksRemaining = max(total - weeksLived, 0)

        let dayComps = calendar.dateComponents([.day], from: birthDate, to: effectiveNow)
        let daysLived = max(dayComps.day ?? 0, 0)

        let monthComps = calendar.dateComponents([.month], from: birthDate, to: effectiveNow)
        let monthsLived = max(monthComps.month ?? 0, 0)

        let ymd = calendar.dateComponents([.year, .month, .day], from: birthDate, to: effectiveNow)
        let years = max(ymd.year ?? 0, 0)
        let months = max(ymd.month ?? 0, 0)
        let days = max(ymd.day ?? 0, 0)

        let fraction = min(max(Double(weeksLived) / Double(total), 0), 1)

        // Summers remaining ≈ remaining full years of expected span (one summer per year).
        let yearsRemaining = max(lifeExpectancyYears - years, 0)
        let summers = bornInFuture ? lifeExpectancyYears : yearsRemaining

        return LifeStats(weeksLived: weeksLived,
                         totalWeeks: total,
                         weeksRemaining: weeksRemaining,
                         daysLived: daysLived,
                         monthsLived: monthsLived,
                         years: years,
                         months: months,
                         days: days,
                         fractionLived: fraction,
                         summersRemaining: summers)
    }

    /// Whole days between now and a target (negative if target has passed).
    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let a = cal.startOfDay(for: from)
        let b = cal.startOfDay(for: to)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }
}
