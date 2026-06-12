import Foundation

struct EarningsSummary {
    var shifts: Int = 0
    var hours: Double = 0
    var wages: Double = 0
    var netTips: Double = 0
    var cashTips: Double = 0
    var cardTips: Double = 0
    var tipOut: Double = 0
    var sales: Double = 0

    var total: Double { wages + netTips }
    var effectiveHourly: Double { hours > 0 ? total / hours : 0 }
    var tipPercent: Double? { sales > 0 ? netTips / sales : nil }
    var avgPerShift: Double { shifts > 0 ? total / Double(shifts) : 0 }
}

struct WeekdayEarning: Identifiable { let weekday: Int; let avg: Double; var id: Int { weekday } }
struct DayTotal: Identifiable { let day: Date; let total: Double; var id: Date { day } }

enum Period: String, CaseIterable, Identifiable {
    case week = "Week", month = "Month", year = "Year", all = "All"
    var id: String { rawValue }
}

enum EarningsEngine {

    static func summarize(_ shifts: [Shift]) -> EarningsSummary {
        var s = EarningsSummary()
        for sh in shifts {
            s.shifts += 1
            s.hours += sh.hoursWorked
            s.wages += sh.wages
            s.netTips += sh.netTips
            s.cashTips += sh.cashTips
            s.cardTips += sh.cardTips
            s.tipOut += sh.tipOut
            s.sales += sh.sales
        }
        return s
    }

    /// Filter shifts to a period anchored at `reference`, respecting a custom
    /// pay-week start weekday (1 = Sunday … 7 = Saturday).
    static func shifts(_ shifts: [Shift], in period: Period, reference: Date = Date(),
                       weekStart: Int = 1, calendar: Calendar = .current) -> [Shift] {
        guard period != .all else { return shifts }
        var cal = calendar
        cal.firstWeekday = weekStart
        let now = reference
        return shifts.filter { sh in
            switch period {
            case .week:  return cal.isDate(sh.date, equalTo: now, toGranularity: .weekOfYear)
            case .month: return cal.isDate(sh.date, equalTo: now, toGranularity: .month)
            case .year:  return cal.isDate(sh.date, equalTo: now, toGranularity: .year)
            case .all:   return true
            }
        }
    }

    static func bestWeekday(_ shifts: [Shift], calendar: Calendar = .current) -> (weekday: Int, avg: Double)? {
        var sums = [Int: (total: Double, count: Int)]()
        for sh in shifts {
            let wd = calendar.component(.weekday, from: sh.date)
            let cur = sums[wd] ?? (0, 0)
            sums[wd] = (cur.total + sh.totalEarnings, cur.count + 1)
        }
        return sums.map { ($0.key, $0.value.count > 0 ? $0.value.total / Double($0.value.count) : 0) }
            .max { $0.1 < $1.1 }
    }

    static func byWeekday(_ shifts: [Shift], calendar: Calendar = .current) -> [WeekdayEarning] {
        var sums = [Int: (total: Double, count: Int)]()
        for sh in shifts {
            let wd = calendar.component(.weekday, from: sh.date)
            let cur = sums[wd] ?? (0, 0)
            sums[wd] = (cur.total + sh.totalEarnings, cur.count + 1)
        }
        return (1...7).map { wd in
            let s = sums[wd]
            let avg = (s != nil && s!.count > 0) ? s!.total / Double(s!.count) : 0
            return WeekdayEarning(weekday: wd, avg: avg)
        }
    }

    /// Daily total earnings over the last `n` days, oldest first.
    static func dailySeries(_ shifts: [Shift], days n: Int, today: Date = Date(),
                            calendar: Calendar = .current) -> [DayTotal] {
        let start = calendar.startOfDay(for: today)
        return (0..<n).reversed().compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let total = shifts.filter { calendar.isDate($0.date, inSameDayAs: d) }.reduce(0) { $0 + $1.totalEarnings }
            return DayTotal(day: d, total: total)
        }
    }

    /// Project this month's total from the pace so far (calendar-month based).
    static func monthProjection(_ shifts: [Shift], reference: Date = Date(), calendar: Calendar = .current) -> Double? {
        let monthShifts = shifts.filter { calendar.isDate($0.date, equalTo: reference, toGranularity: .month) }
        guard !monthShifts.isEmpty else { return nil }
        let earned = monthShifts.reduce(0) { $0 + $1.totalEarnings }
        let day = calendar.component(.day, from: reference)
        guard let range = calendar.range(of: .day, in: .month, for: reference), day > 0 else { return nil }
        let daysInMonth = range.count
        return earned / Double(day) * Double(daysInMonth)
    }

    static func taxSetAside(_ total: Double, rate: Double) -> Double { total * rate }
}
