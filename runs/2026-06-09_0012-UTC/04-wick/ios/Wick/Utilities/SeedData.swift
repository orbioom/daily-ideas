import Foundation
import SwiftData

/// Optional realistic sample trades to explore analytics immediately.
enum SeedData {
    static func loadSample(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        struct S {
            let sym: String; let asset: AssetType; let dir: Direction; let strat: Strategy
            let entry: Double; let exit: Double?; let qty: Double; let stop: Double?
            let target: Double?; let daysAgoEntry: Int; let holdHours: Int; let disc: Int
        }
        let samples: [S] = [
            S(sym: "AAPL", asset: .stock, dir: .long, strat: .breakout, entry: 188.4, exit: 194.2, qty: 50, stop: 185.0, target: 196, daysAgoEntry: 38, holdHours: 30, disc: 4),
            S(sym: "TSLA", asset: .stock, dir: .short, strat: .reversal, entry: 245.0, exit: 251.3, qty: 30, stop: 252.0, target: 232, daysAgoEntry: 35, holdHours: 6, disc: 2),
            S(sym: "NVDA", asset: .stock, dir: .long, strat: .trend, entry: 118.2, exit: 131.5, qty: 40, stop: 113.0, target: 135, daysAgoEntry: 31, holdHours: 96, disc: 5),
            S(sym: "BTC", asset: .crypto, dir: .long, strat: .pullback, entry: 61250, exit: 64800, qty: 0.4, stop: 59800, target: 66000, daysAgoEntry: 28, holdHours: 50, disc: 4),
            S(sym: "EURUSD", asset: .forex, dir: .short, strat: .range, entry: 1.0920, exit: 1.0875, qty: 50000, stop: 1.0945, target: 1.0860, daysAgoEntry: 24, holdHours: 20, disc: 3),
            S(sym: "AMD", asset: .stock, dir: .long, strat: .breakout, entry: 162.0, exit: 158.4, qty: 60, stop: 158.0, target: 172, daysAgoEntry: 20, holdHours: 8, disc: 2),
            S(sym: "SPY", asset: .etf, dir: .long, strat: .swing, entry: 521.3, exit: 533.1, qty: 25, stop: 515.0, target: 535, daysAgoEntry: 17, holdHours: 120, disc: 5),
            S(sym: "MSFT", asset: .stock, dir: .long, strat: .pullback, entry: 415.0, exit: 409.2, qty: 20, stop: 408.0, target: 428, daysAgoEntry: 12, holdHours: 18, disc: 3),
            S(sym: "ETH", asset: .crypto, dir: .long, strat: .trend, entry: 3320, exit: 3585, qty: 3, stop: 3210, target: 3650, daysAgoEntry: 9, holdHours: 72, disc: 4),
            S(sym: "COIN", asset: .stock, dir: .short, strat: .news, entry: 232.0, exit: 224.5, qty: 25, stop: 238.0, target: 218, daysAgoEntry: 6, holdHours: 5, disc: 4),
            S(sym: "NFLX", asset: .stock, dir: .long, strat: .breakout, entry: 642.0, exit: nil, qty: 10, stop: 628.0, target: 680, daysAgoEntry: 2, holdHours: 0, disc: 0)
        ]

        for s in samples {
            let entryDate = cal.date(byAdding: .day, value: -s.daysAgoEntry, to: now) ?? now
            let exitDate = s.exit == nil ? nil : cal.date(byAdding: .hour, value: s.holdHours, to: entryDate)
            let fees = max(1, s.entry * s.qty * 0.0005)
            let t = Trade(symbol: s.sym, assetType: s.asset, direction: s.dir, strategy: s.strat,
                          entryDate: entryDate, entryPrice: s.entry, quantity: s.qty, fees: fees,
                          exitDate: exitDate, exitPrice: s.exit, stopPrice: s.stop,
                          targetPrice: s.target, discipline: s.disc)
            context.insert(t)
        }
        try? context.save()
    }
}
