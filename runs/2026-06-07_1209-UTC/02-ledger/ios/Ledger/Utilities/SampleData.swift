import Foundation
import SwiftData

/// Seeds a realistic multi-account portfolio, allocation targets, and a year of
/// monthly snapshots so the trend, allocation, and rebalancing screens are alive.
enum SampleData {
    static func seed(into context: ModelContext) {
        let accounts: [Account] = [
            Account(name: "Checking", institution: "First Federal", type: .asset, assetClass: .cash, balance: 8_400),
            Account(name: "High-Yield Savings", institution: "Ally", type: .asset, assetClass: .cash, balance: 24_000),
            Account(name: "401(k)", institution: "Fidelity", type: .asset, assetClass: .stocks, balance: 118_000),
            Account(name: "Roth IRA", institution: "Vanguard", type: .asset, assetClass: .stocks, balance: 46_500),
            Account(name: "Bond Fund", institution: "Vanguard", type: .asset, assetClass: .bonds, balance: 31_000),
            Account(name: "Home Equity", institution: "—", type: .asset, assetClass: .realEstate, balance: 165_000),
            Account(name: "BTC + ETH", institution: "Coinbase", type: .asset, assetClass: .crypto, balance: 9_200),
            Account(name: "Mortgage", institution: "Rocket", type: .liability, assetClass: .debt, balance: 212_000),
            Account(name: "Car Loan", institution: "Toyota", type: .liability, assetClass: .debt, balance: 14_300),
        ]
        for a in accounts { context.insert(a) }

        let targets: [Target] = [
            Target(assetClass: .cash, percent: 10),
            Target(assetClass: .stocks, percent: 50),
            Target(assetClass: .bonds, percent: 15),
            Target(assetClass: .realEstate, percent: 20),
            Target(assetClass: .crypto, percent: 5),
        ]
        for t in targets { context.insert(t) }

        // 13 monthly snapshots showing growth from ~$140k to today.
        let cal = Calendar.current
        let base = AllocationEngine.netWorth(accounts)
        for m in stride(from: 12, through: 1, by: -1) {
            guard let date = cal.date(byAdding: .month, value: -m, to: Date()) else { continue }
            let growth = 1.0 - (Double(m) * 0.018) - Double.random(in: -0.01...0.01)
            let snap = Snapshot(date: date, note: "")
            for a in accounts {
                let factor = a.type == .liability ? (1.0 + Double(m) * 0.004) : growth
                snap.entries.append(SnapshotEntry(accountName: a.name, classRaw: a.classRaw,
                                                  isLiability: a.type == .liability,
                                                  value: a.balance * factor))
            }
            context.insert(snap)
        }
        // today's snapshot at current balances
        let today = Snapshot(date: Date(), note: "Current")
        for a in accounts {
            today.entries.append(SnapshotEntry(accountName: a.name, classRaw: a.classRaw,
                                               isLiability: a.type == .liability, value: a.balance))
        }
        context.insert(today)
        _ = base
    }
}
