import Foundation

/// On-device cycle prediction. Learns average cycle and period length from your
/// logged history and projects the next period, fertile window, and ovulation.
/// Estimates only — not contraception or medical advice.
struct CyclePredictor {
    enum Phase: String {
        case menstrual = "Menstrual"
        case follicular = "Follicular"
        case fertile = "Fertile window"
        case ovulation = "Ovulation"
        case luteal = "Luteal"
        case unknown = "Not enough data"

        var detail: String {
            switch self {
            case .menstrual: return "Your period. Rest and be kind to yourself."
            case .follicular: return "Energy usually rises as your body prepares to ovulate."
            case .fertile: return "Your most fertile days are around now."
            case .ovulation: return "Ovulation is estimated around today."
            case .luteal: return "The wind-down phase. PMS symptoms can appear."
            case .unknown: return "Log a couple of periods to unlock predictions."
            }
        }
        var symbol: String {
            switch self {
            case .menstrual: return "drop.fill"
            case .follicular: return "leaf.fill"
            case .fertile: return "sparkles"
            case .ovulation: return "circle.circle.fill"
            case .luteal: return "moon.fill"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    let averageCycle: Int
    let averagePeriod: Int
    let cycleLengths: [Int]
    let lastPeriodStart: Date?
    let nextPeriodStart: Date?
    let ovulationDate: Date?
    let fertileStart: Date?
    let fertileEnd: Date?
    let currentCycleDay: Int?
    let phase: Phase
    let hasEnoughData: Bool
    /// Standard deviation of cycle length — a regularity signal.
    let regularity: Double?

    static func make(periods: [Period],
                     defaultCycle: Int = 28,
                     defaultPeriod: Int = 5,
                     calendar: Calendar = .current,
                     now: Date = .now) -> CyclePredictor {
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        let today = calendar.startOfDay(for: now)

        // Cycle lengths between consecutive period starts.
        var lengths: [Int] = []
        for i in 1..<max(1, sorted.count) {
            let d = calendar.dateComponents([.day], from: sorted[i-1].startDate, to: sorted[i].startDate).day ?? 0
            if d > 10 && d < 90 { lengths.append(d) }   // discard implausible values
        }
        let recent = Array(lengths.suffix(6))
        let avgCycle = recent.isEmpty ? defaultCycle : Int((Double(recent.reduce(0, +)) / Double(recent.count)).rounded())

        let periodLens = sorted.map { $0.lengthDays }.filter { $0 <= 14 }
        let avgPeriod = periodLens.isEmpty ? defaultPeriod : Int((Double(periodLens.reduce(0, +)) / Double(periodLens.count)).rounded())

        let regularity: Double? = recent.count >= 2 ? stdev(recent.map(Double.init)) : nil

        let hasData = !sorted.isEmpty
        let lastStart = sorted.last?.startDate

        var next: Date?, ovulation: Date?, fStart: Date?, fEnd: Date?, cycleDay: Int?
        var phase: Phase = hasData ? .unknown : .unknown

        if let last = lastStart {
            next = calendar.date(byAdding: .day, value: avgCycle, to: last)
            if let next {
                ovulation = calendar.date(byAdding: .day, value: -14, to: next)
                if let ov = ovulation {
                    fStart = calendar.date(byAdding: .day, value: -5, to: ov)
                    fEnd = calendar.date(byAdding: .day, value: 1, to: ov)
                }
            }
            let dayDiff = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            cycleDay = dayDiff + 1

            // Determine phase from today's relationship to predicted markers.
            phase = computePhase(today: today, lastStart: last, avgPeriod: avgPeriod,
                                 ovulation: ovulation, fStart: fStart, fEnd: fEnd,
                                 periods: sorted, calendar: calendar,
                                 hasEnough: lengths.count >= 1)
        }

        return CyclePredictor(averageCycle: avgCycle, averagePeriod: avgPeriod,
                              cycleLengths: lengths, lastPeriodStart: lastStart,
                              nextPeriodStart: next, ovulationDate: ovulation,
                              fertileStart: fStart, fertileEnd: fEnd,
                              currentCycleDay: cycleDay, phase: phase,
                              hasEnoughData: lengths.count >= 1, regularity: regularity)
    }

    private static func computePhase(today: Date, lastStart: Date, avgPeriod: Int,
                                     ovulation: Date?, fStart: Date?, fEnd: Date?,
                                     periods: [Period], calendar: Calendar, hasEnough: Bool) -> Phase {
        // Are we inside a logged or current period?
        if periods.contains(where: { $0.contains(today) }) { return .menstrual }
        let dayDiff = calendar.dateComponents([.day], from: lastStart, to: today).day ?? 0
        if dayDiff < avgPeriod { return .menstrual }
        guard hasEnough else { return .unknown }
        if let ov = ovulation, calendar.isDate(today, inSameDayAs: ov) { return .ovulation }
        if let fs = fStart, let fe = fEnd, today >= fs && today <= fe { return .fertile }
        if let ov = ovulation, today > ov { return .luteal }
        return .follicular
    }

    /// Days until the next period (negative = late).
    func daysUntilNextPeriod(now: Date = .now) -> Int? {
        guard let next = nextPeriodStart else { return nil }
        let today = Calendar.current.startOfDay(for: now)
        return Calendar.current.dateComponents([.day], from: today, to: next).day
    }

    /// Classify a date for calendar rendering.
    enum DayKind { case period, predictedPeriod, fertile, ovulation, none }

    func kind(for date: Date, periods: [Period], calendar: Calendar = .current) -> DayKind {
        let d = calendar.startOfDay(for: date)
        if periods.contains(where: { $0.contains(d) }) { return .period }
        if let ov = ovulationDate, calendar.isDate(d, inSameDayAs: ov) { return .ovulation }
        if let fs = fertileStart, let fe = fertileEnd, d >= fs && d <= fe { return .fertile }
        if let next = nextPeriodStart {
            let end = calendar.date(byAdding: .day, value: averagePeriod - 1, to: next) ?? next
            if d >= next && d <= end { return .predictedPeriod }
        }
        return .none
    }

    private static func stdev(_ xs: [Double]) -> Double {
        guard xs.count >= 2 else { return 0 }
        let m = xs.reduce(0, +) / Double(xs.count)
        let v = xs.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(xs.count - 1)
        return v.squareRoot()
    }
}
