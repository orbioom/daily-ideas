import Foundation

/// A labeled aggregate used by breakdown charts and lists.
struct Breakdown: Identifiable {
    let id: String        // the category key (stake, location, game, etc.)
    let label: String
    let profit: Decimal
    let count: Int
}

/// A single point on the cumulative-profit or bankroll timeline.
struct TimePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Decimal
}

/// A point on a monthly bar series.
struct MonthlyPoint: Identifiable {
    let id: String        // "2026-03"
    let date: Date        // first of month, for axis ordering
    let label: String     // "Mar"
    let profit: Decimal
    let count: Int
}

/// Pure, fully-guarded analytics over sessions and bankroll transactions.
/// No SwiftData, no SwiftUI — testable and safe to call off the view's hot path.
struct StatsEngine {
    let sessions: [Session]
    let transactions: [BankrollTransaction]

    init(sessions: [Session], transactions: [BankrollTransaction] = []) {
        self.sessions = sessions
        self.transactions = transactions
    }

    // MARK: - Core figures

    var sessionCount: Int { sessions.count }

    var totalProfit: Decimal {
        sessions.reduce(Decimal(0)) { $0 + $1.profit }
    }

    /// Total played time in hours (Σ minutes / 60), guarded against negatives.
    var totalHours: Double {
        let minutes = sessions.reduce(0) { $0 + max(0, $1.durationMinutes) }
        return Double(minutes) / 60.0
    }

    /// Profit per hour. Returns nil when no time is logged (guarded division).
    var hourlyRate: Decimal? {
        let hours = totalHours
        guard hours > 0 else { return nil }
        let hoursDecimal = Decimal(hours)
        return totalProfit / hoursDecimal
    }

    /// Share of winning sessions as a percentage 0–100.
    var winRate: Double {
        guard !sessions.isEmpty else { return 0 }
        let wins = sessions.filter { $0.profit > 0 }.count
        return Double(wins) / Double(sessions.count) * 100.0
    }

    var biggestWin: Decimal? {
        sessions.map(\.profit).filter { $0 > 0 }.max()
    }

    var biggestLoss: Decimal? {
        sessions.map(\.profit).filter { $0 < 0 }.min()
    }

    /// Average net result per session. Returns nil with no sessions (guarded).
    var averageProfit: Decimal? {
        guard !sessions.isEmpty else { return nil }
        return totalProfit / Decimal(sessions.count)
    }

    /// ROI across tournament sessions: tournament profit / total tournament buy-ins.
    /// Returns nil when there are no tournament buy-ins (guarded).
    var tournamentROI: Double? {
        let tourneys = sessions.filter { $0.format == .tournament }
        let buyIns = tourneys.reduce(Decimal(0)) { $0 + $1.buyIn }
        guard buyIns > 0 else { return nil }
        let profit = tourneys.reduce(Decimal(0)) { $0 + $1.profit }
        return decimalToDouble(profit / buyIns) * 100.0
    }

    /// Population standard deviation of session results (a simple variance measure).
    /// Returns nil with fewer than two sessions (guarded).
    var standardDeviation: Decimal? {
        guard sessions.count > 1 else { return nil }
        let values = sessions.map { decimalToDouble($0.profit) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        let sd = variance >= 0 ? variance.squareRoot() : 0
        return Decimal(sd)
    }

    // MARK: - Bankroll

    /// Net of all bankroll deposits/withdrawals.
    var netDeposits: Decimal {
        transactions.reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    /// Current bankroll = net deposits + total session profit.
    var currentBankroll: Decimal {
        netDeposits + totalProfit
    }

    /// Bankroll value over time, combining deposits/withdrawals and session results,
    /// ordered chronologically. Each event moves the running balance.
    var bankrollTimeline: [TimePoint] {
        struct Event { let date: Date; let delta: Decimal }
        var events: [Event] = []
        for t in transactions { events.append(Event(date: t.date, delta: t.signedAmount)) }
        for s in sessions { events.append(Event(date: s.date, delta: s.profit)) }
        guard !events.isEmpty else { return [] }
        let sorted = events.sorted { $0.date < $1.date }
        var running = Decimal(0)
        var points: [TimePoint] = []
        for e in sorted {
            running += e.delta
            points.append(TimePoint(date: e.date, value: running))
        }
        return points
    }

    // MARK: - Cumulative profit (sessions only)

    /// Running session profit over time, oldest → newest.
    var cumulativeProfit: [TimePoint] {
        let sorted = sessions.sorted { $0.date < $1.date }
        var running = Decimal(0)
        var points: [TimePoint] = []
        for s in sorted {
            running += s.profit
            points.append(TimePoint(date: s.date, value: running))
        }
        return points
    }

    // MARK: - Breakdowns

    func breakdown(by key: (Session) -> String, label: ((String) -> String)? = nil) -> [Breakdown] {
        var profits: [String: Decimal] = [:]
        var counts: [String: Int] = [:]
        for s in sessions {
            let raw = key(s)
            let k = raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : raw
            profits[k, default: 0] += s.profit
            counts[k, default: 0] += 1
        }
        return profits.keys.map { k in
            Breakdown(id: k,
                      label: label?(k) ?? k,
                      profit: profits[k] ?? 0,
                      count: counts[k] ?? 0)
        }
        .sorted { $0.profit > $1.profit }
    }

    var byStake: [Breakdown] { breakdown { $0.stakes } }
    var byLocation: [Breakdown] { breakdown { $0.location } }
    var byGameType: [Breakdown] { breakdown(by: { $0.gameType.rawValue }) }
    var byFormat: [Breakdown] { breakdown(by: { $0.format.rawValue }) }

    /// Monthly profit bars, ordered chronologically.
    var byMonth: [MonthlyPoint] {
        let cal = Calendar.current
        var profits: [String: Decimal] = [:]
        var counts: [String: Int] = [:]
        var firstDate: [String: Date] = [:]

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        for s in sessions {
            let comps = cal.dateComponents([.year, .month], from: s.date)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = String(format: "%04d-%02d", year, month)
            profits[key, default: 0] += s.profit
            counts[key, default: 0] += 1
            if let start = cal.date(from: DateComponents(year: year, month: month, day: 1)) {
                firstDate[key] = start
            }
        }

        return profits.keys.compactMap { key -> MonthlyPoint? in
            guard let date = firstDate[key] else { return nil }
            return MonthlyPoint(id: key,
                                date: date,
                                label: monthFormatter.string(from: date),
                                profit: profits[key] ?? 0,
                                count: counts[key] ?? 0)
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Bankroll management guidance

    /// The largest single buy-in seen across sessions, used as the basis for guidance.
    var typicalBuyIn: Decimal? {
        let buyIns = sessions.map(\.buyIn).filter { $0 > 0 }
        return buyIns.max()
    }

    /// Recommended minimum bankroll = `buyIns` × typical buy-in (informational only).
    func recommendedBankroll(buyIns: Int) -> Decimal? {
        guard let unit = typicalBuyIn, buyIns > 0 else { return nil }
        return unit * Decimal(buyIns)
    }

    // MARK: - Helpers

    /// Safe Decimal → Double for variance / ROI math (NaN-guarded).
    private func decimalToDouble(_ d: Decimal) -> Double {
        let v = NSDecimalNumber(decimal: d).doubleValue
        return v.isFinite ? v : 0
    }
}

/// A filter window for analytics.
enum StatsPeriod: String, CaseIterable, Identifiable {
    case all = "All"
    case ytd = "YTD"
    case last30 = "30d"
    case last90 = "90d"

    var id: String { rawValue }

    /// Filter sessions to this period relative to `now`.
    func filter(_ sessions: [Session], now: Date = .now) -> [Session] {
        let cal = Calendar.current
        switch self {
        case .all:
            return sessions
        case .ytd:
            guard let startOfYear = cal.date(from: cal.dateComponents([.year], from: now)) else {
                return sessions
            }
            return sessions.filter { $0.date >= startOfYear }
        case .last30:
            guard let start = cal.date(byAdding: .day, value: -30, to: now) else { return sessions }
            return sessions.filter { $0.date >= start }
        case .last90:
            guard let start = cal.date(byAdding: .day, value: -90, to: now) else { return sessions }
            return sessions.filter { $0.date >= start }
        }
    }
}
