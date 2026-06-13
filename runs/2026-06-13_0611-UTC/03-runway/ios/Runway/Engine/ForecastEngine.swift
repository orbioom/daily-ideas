import Foundation

struct FlowEvent: Identifiable {
    let id = UUID()
    let name: String
    let signedAmount: Double
    let category: String
    let kind: FlowKind
    let isRecurring: Bool
}

struct DayProjection: Identifiable {
    let date: Date
    var events: [FlowEvent]
    var startBalance: Double
    var endBalance: Double

    var id: Date { date }
    var income: Double { events.filter { $0.kind == .income }.reduce(0) { $0 + $1.signedAmount } }
    var expense: Double { events.filter { $0.kind == .bill }.reduce(0) { $0 + (-$1.signedAmount) } }
    var net: Double { income - expense }
}

struct Forecast {
    let projections: [DayProjection]
    let openingBalance: Double
    let buffer: Double
    let nextIncomeDate: Date?
    let nextIncomeAmount: Double
    let safeToSpend: Double
    let lowestBalance: Double
    let lowestDate: Date?
    let warningDays: [DayProjection]
}

struct ForecastEngine {
    let openingBalance: Double
    let asOf: Date
    let recurring: [RecurringItem]
    let oneOffs: [OneOffItem]
    let buffer: Double

    private let cal = Calendar.current

    // MARK: occurrence test

    private func clampedDay(_ day: Int, in date: Date) -> Int {
        let range = cal.range(of: .day, in: .month, for: date) ?? (1..<29)
        let last = range.upperBound - 1
        if day <= 0 { return last }          // 0 means "month end"
        return min(day, last)
    }

    private func monthsBetween(_ a: Date, _ b: Date) -> Int {
        let ca = cal.dateComponents([.year, .month], from: a)
        let cb = cal.dateComponents([.year, .month], from: b)
        return ((cb.year ?? 0) - (ca.year ?? 0)) * 12 + ((cb.month ?? 0) - (ca.month ?? 0))
    }

    private func occurs(_ item: RecurringItem, on day: Date) -> Bool {
        let d = cal.startOfDay(for: day)
        let anchor = cal.startOfDay(for: item.anchorDate)
        guard d >= anchor else { return false }
        switch item.cadence {
        case .weekly, .biweekly, .everyNWeeks:
            let step = item.cadence == .weekly ? 1 : (item.cadence == .biweekly ? 2 : item.interval)
            let days = cal.dateComponents([.day], from: anchor, to: d).day ?? 0
            return days % (7 * max(1, step)) == 0
        case .monthly, .everyNMonths:
            let stepMonths = item.cadence == .monthly ? 1 : max(1, item.interval)
            guard monthsBetween(anchor, d) % stepMonths == 0 else { return false }
            return cal.component(.day, from: d) == clampedDay(item.dayOfMonth, in: d)
        case .semimonthly:
            let dayNum = cal.component(.day, from: d)
            return dayNum == clampedDay(item.dayOfMonth, in: d)
                || dayNum == clampedDay(item.secondDayOfMonth, in: d)
        }
    }

    // MARK: projection

    func run(days: Int) -> Forecast {
        let start = cal.startOfDay(for: asOf)
        var projections: [DayProjection] = []
        var balance = openingBalance

        let activeRecurring = recurring.filter { $0.isActive }

        for offset in 0..<max(1, days) {
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { continue }
            var events: [FlowEvent] = []

            for item in activeRecurring where occurs(item, on: day) {
                events.append(FlowEvent(name: item.name, signedAmount: item.signedAmount,
                                        category: item.category, kind: item.kind, isRecurring: true))
            }
            for off in oneOffs where cal.isDate(off.date, inSameDayAs: day) {
                events.append(FlowEvent(name: off.name, signedAmount: off.signedAmount,
                                        category: off.category, kind: off.kind, isRecurring: false))
            }

            let opening = balance
            let net = events.reduce(0) { $0 + $1.signedAmount }
            balance += net
            projections.append(DayProjection(date: day, events: events,
                                             startBalance: opening, endBalance: balance))
        }

        // next income strictly after today
        let payday = projections.first { $0.income > 0 && $0.date > start }
        let nextIncomeDate = payday?.date
        let nextIncomeAmount = payday?.income ?? 0

        // safe to spend: lowest balance before the next payday, minus buffer
        let preBalances: [Double]
        if let idx = projections.firstIndex(where: { $0.date == nextIncomeDate }) {
            preBalances = projections[0..<idx].map { $0.endBalance }
        } else {
            preBalances = projections.map { $0.endBalance }
        }
        let minPre = min(openingBalance, preBalances.min() ?? openingBalance)
        let safe = max(0, minPre - buffer)

        let lowest = projections.min { $0.endBalance < $1.endBalance }
        let warnings = projections.filter { $0.endBalance < buffer && !$0.events.isEmpty }

        return Forecast(projections: projections, openingBalance: openingBalance, buffer: buffer,
                        nextIncomeDate: nextIncomeDate, nextIncomeAmount: nextIncomeAmount,
                        safeToSpend: safe, lowestBalance: lowest?.endBalance ?? openingBalance,
                        lowestDate: lowest?.date, warningDays: warnings)
    }
}
