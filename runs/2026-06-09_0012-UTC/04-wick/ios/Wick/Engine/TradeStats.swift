import Foundation

/// Pure analytics over closed trades: win rate, profit factor, expectancy,
/// R-stats, equity curve, and breakdowns. Open trades are excluded from P/L.
enum TradeStats {

    static func closed(_ trades: [Trade]) -> [Trade] {
        trades.filter { !$0.isOpen }.sorted { ($0.exitDate ?? .distantPast) < ($1.exitDate ?? .distantPast) }
    }

    struct Summary {
        var count = 0
        var wins = 0
        var losses = 0
        var totalPL = 0.0
        var grossProfit = 0.0
        var grossLoss = 0.0     // positive magnitude
        var largestWin = 0.0
        var largestLoss = 0.0   // signed (negative)
        var avgHold: TimeInterval = 0

        var winRate: Double { count > 0 ? Double(wins) / Double(count) : 0 }
        var avgWin: Double { wins > 0 ? grossProfit / Double(wins) : 0 }
        var avgLoss: Double { losses > 0 ? grossLoss / Double(losses) : 0 }
        /// Gross profit ÷ gross loss. Nil when there are no losses yet.
        var profitFactor: Double? { grossLoss > 0 ? grossProfit / grossLoss : nil }
        /// Average P/L per trade.
        var expectancy: Double { count > 0 ? totalPL / Double(count) : 0 }
        /// Expectancy expressed in R using win/loss probabilities.
        var expectancyR: Double {
            guard count > 0 else { return 0 }
            let pWin = winRate
            let avgW = avgWin, avgL = avgLoss
            guard avgL > 0 else { return pWin > 0 ? Double.infinity : 0 }
            // (pWin * avgWin - pLoss * avgLoss) / avgLoss  → expectancy in units of avg loss
            return (pWin * avgW - (1 - pWin) * avgL) / avgL
        }
    }

    static func summary(_ trades: [Trade]) -> Summary {
        var s = Summary()
        let cl = closed(trades)
        s.count = cl.count
        var holdSum: TimeInterval = 0
        var holdCount = 0
        for t in cl {
            guard let pl = t.netPL else { continue }
            s.totalPL += pl
            if pl >= 0 {
                s.wins += 1; s.grossProfit += pl
                s.largestWin = max(s.largestWin, pl)
            } else {
                s.losses += 1; s.grossLoss += -pl
                s.largestLoss = min(s.largestLoss, pl)
            }
            if let h = t.holdingInterval { holdSum += h; holdCount += 1 }
        }
        s.avgHold = holdCount > 0 ? holdSum / Double(holdCount) : 0
        return s
    }

    // MARK: - Equity curve

    struct EquityPoint: Identifiable {
        let id = UUID()
        let date: Date
        let equity: Double
        let tradePL: Double
    }

    static func equityCurve(_ trades: [Trade], startingBalance: Double) -> [EquityPoint] {
        let cl = closed(trades)
        guard let firstTrade = cl.first else { return [] }
        var running = startingBalance
        var out: [EquityPoint] = [EquityPoint(date: firstTrade.entryDate, equity: running, tradePL: 0)]
        for t in cl {
            guard let pl = t.netPL, let date = t.exitDate else { continue }
            running += pl
            out.append(EquityPoint(date: date, equity: running, tradePL: pl))
        }
        return out
    }

    // MARK: - Streak

    /// Current consecutive win (+) or loss (−) streak of most recent closed trades.
    static func currentStreak(_ trades: [Trade]) -> Int {
        let cl = closed(trades).reversed()
        var streak = 0
        var sign = 0
        for t in cl {
            guard let win = t.isWin else { continue }
            let s = win ? 1 : -1
            if sign == 0 { sign = s; streak = s }
            else if s == sign { streak += s }
            else { break }
        }
        return streak
    }

    // MARK: - Breakdowns

    struct GroupPL: Identifiable {
        let id = UUID()
        let label: String
        let pl: Double
        let count: Int
        let tint: ColorBox
    }

    /// Wrapper so SwiftUI Color isn't needed in this pure file.
    struct ColorBox { let hex: UInt32 }

    static func byStrategy(_ trades: [Trade]) -> [GroupPL] {
        let cl = closed(trades)
        let groups = Dictionary(grouping: cl, by: { $0.strategy })
        return groups.map { strat, ts in
            GroupPL(label: strat.title,
                    pl: ts.reduce(0) { $0 + ($1.netPL ?? 0) },
                    count: ts.count,
                    tint: ColorBox(hex: strategyHex(strat)))
        }.sorted { $0.pl > $1.pl }
    }

    static func bySymbol(_ trades: [Trade], top: Int = 6) -> [GroupPL] {
        let cl = closed(trades)
        let groups = Dictionary(grouping: cl, by: { $0.symbol })
        return groups.map { sym, ts in
            GroupPL(label: sym,
                    pl: ts.reduce(0) { $0 + ($1.netPL ?? 0) },
                    count: ts.count,
                    tint: ColorBox(hex: 0x5E8FA8))
        }.sorted { abs($0.pl) > abs($1.pl) }.prefix(top).map { $0 }
    }

    private static func strategyHex(_ s: Strategy) -> UInt32 {
        switch s {
        case .breakout: return 0x4FA8A0
        case .pullback: return 0x5E8FA8
        case .reversal: return 0x8B6FB0
        case .trend: return 0x3E9E78
        case .scalp: return 0xC08A4E
        case .swing: return 0x5A6BB0
        case .news: return 0xC0553E
        case .range: return 0x6E8F5E
        case .other: return 0x6E7287
        }
    }

    // MARK: - Calendar

    /// Net P/L per calendar day for a given month.
    static func dailyPL(_ trades: [Trade], month: Date, calendar: Calendar = .current) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for t in closed(trades) {
            guard let exit = t.exitDate, let pl = t.netPL,
                  calendar.isDate(exit, equalTo: month, toGranularity: .month) else { continue }
            let day = calendar.startOfDay(for: exit)
            out[day, default: 0] += pl
        }
        return out
    }
}
