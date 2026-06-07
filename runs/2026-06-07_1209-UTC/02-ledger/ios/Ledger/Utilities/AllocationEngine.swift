import Foundation

/// One asset class's current vs target standing.
struct AllocationRow: Identifiable {
    var id: String { assetClass.rawValue }
    let assetClass: AssetClass
    let currentValue: Double
    let currentPercent: Double
    let targetPercent: Double
    /// Percentage-point drift (current − target). Positive = overweight.
    var driftPoints: Double { currentPercent - targetPercent }
    /// Dollar amount to add (+) or trim (−) to reach target.
    let rebalanceAmount: Double
}

/// Pure allocation + rebalancing math over a set of accounts and targets.
enum AllocationEngine {

    /// Net worth = assets − liabilities, over the included accounts.
    static func netWorth(_ accounts: [Account]) -> Double {
        accounts.filter { $0.includeInNetWorth && !$0.archived }
            .map { $0.signedValue }.reduce(0, +)
    }

    static func totalAssets(_ accounts: [Account]) -> Double {
        accounts.filter { $0.type == .asset && !$0.archived }
            .map { $0.balance }.reduce(0, +)
    }

    static func totalLiabilities(_ accounts: [Account]) -> Double {
        accounts.filter { $0.type == .liability && !$0.archived }
            .map { $0.balance }.reduce(0, +)
    }

    /// Current value held in each investable asset class (assets only).
    static func valueByClass(_ accounts: [Account]) -> [AssetClass: Double] {
        var out: [AssetClass: Double] = [:]
        for a in accounts where a.type == .asset && !a.archived {
            out[a.assetClass, default: 0] += a.balance
        }
        return out
    }

    /// Build current-vs-target rows. Targets are percentages of total assets;
    /// rebalance amounts move you from current to target at the current total.
    static func rows(accounts: [Account], targets: [Target]) -> [AllocationRow] {
        let byClass = valueByClass(accounts)
        let total = byClass.values.reduce(0, +)
        var targetMap: [AssetClass: Double] = [:]
        for t in targets { targetMap[t.assetClass, default: 0] += max(0, t.percent) }

        let classes = Set(byClass.keys).union(targetMap.keys)
        let ordered = AssetClass.investable.filter { classes.contains($0) }

        return ordered.map { cls in
            let value = byClass[cls] ?? 0
            let curPct = total > 0 ? value / total * 100 : 0
            let tgtPct = targetMap[cls] ?? 0
            let targetValue = total * tgtPct / 100
            return AllocationRow(assetClass: cls,
                                 currentValue: value,
                                 currentPercent: curPct,
                                 targetPercent: tgtPct,
                                 rebalanceAmount: targetValue - value)
        }
    }

    /// Sum of all target percentages — should be 100 for a complete plan.
    static func targetTotal(_ targets: [Target]) -> Double {
        targets.map { max(0, $0.percent) }.reduce(0, +)
    }

    /// Largest absolute drift across classes (portfolio "out-of-balance" score).
    static func maxDrift(_ rows: [AllocationRow]) -> Double {
        rows.map { abs($0.driftPoints) }.max() ?? 0
    }
}

/// Currency + percent formatting helpers.
enum Money {
    static func string(_ value: Double, code: String = "USD") -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = abs(value) >= 1000 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    static func compact(_ value: Double, code: String = "USD") -> String {
        let sign = value < 0 ? "-" : ""
        let v = abs(value)
        let symbol = symbolFor(code)
        switch v {
        case 1_000_000...: return "\(sign)\(symbol)\(String(format: "%.2f", v/1_000_000))M"
        case 10_000...: return "\(sign)\(symbol)\(String(format: "%.0f", v/1_000))K"
        case 1_000...: return "\(sign)\(symbol)\(String(format: "%.1f", v/1_000))K"
        default: return "\(sign)\(symbol)\(String(format: "%.0f", v))"
        }
    }
    static func symbolFor(_ code: String) -> String {
        switch code { case "EUR": return "€"; case "GBP": return "£"; case "JPY": return "¥"; default: return "$" }
    }
    static func percent(_ value: Double) -> String { String(format: "%.1f%%", value) }
}
