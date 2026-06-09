import Foundation
import SwiftData

/// A single trade. Open while `exitPrice`/`exitDate` are nil; closed once set.
/// All P/L is derived — never stored — so it can't drift from the inputs.
@Model
final class Trade {
    var symbol: String
    var assetTypeRaw: String
    var directionRaw: String
    var strategyRaw: String

    var entryDate: Date
    var exitDate: Date?
    var entryPrice: Double
    var exitPrice: Double?
    var quantity: Double
    var fees: Double

    var stopPrice: Double?
    var targetPrice: Double?

    var discipline: Int     // 1…5 self-rating, 0 = unrated
    var notes: String
    var createdAt: Date

    init(symbol: String,
         assetType: AssetType = .stock,
         direction: Direction = .long,
         strategy: Strategy = .other,
         entryDate: Date = .now,
         entryPrice: Double,
         quantity: Double,
         fees: Double = 0,
         exitDate: Date? = nil,
         exitPrice: Double? = nil,
         stopPrice: Double? = nil,
         targetPrice: Double? = nil,
         discipline: Int = 0,
         notes: String = "") {
        self.symbol = symbol.uppercased()
        self.assetTypeRaw = assetType.rawValue
        self.directionRaw = direction.rawValue
        self.strategyRaw = strategy.rawValue
        self.entryDate = entryDate
        self.entryPrice = max(0, entryPrice)
        self.quantity = max(0, quantity)
        self.fees = max(0, fees)
        self.exitDate = exitDate
        self.exitPrice = exitPrice
        self.stopPrice = stopPrice
        self.targetPrice = targetPrice
        self.discipline = min(max(discipline, 0), 5)
        self.notes = notes
        self.createdAt = .now
    }

    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRaw) ?? .stock }
        set { assetTypeRaw = newValue.rawValue }
    }
    var direction: Direction {
        get { Direction(rawValue: directionRaw) ?? .long }
        set { directionRaw = newValue.rawValue }
    }
    var strategy: Strategy {
        get { Strategy(rawValue: strategyRaw) ?? .other }
        set { strategyRaw = newValue.rawValue }
    }

    var isOpen: Bool { exitPrice == nil || exitDate == nil }

    /// Net profit/loss after fees, in account currency. Nil while open.
    var netPL: Double? {
        guard let exit = exitPrice else { return nil }
        let gross = (exit - entryPrice) * direction.sign * quantity
        return gross - fees
    }

    var isWin: Bool? {
        guard let pl = netPL else { return nil }
        return pl >= 0
    }

    /// Return on the position's notional cost.
    var returnPct: Double? {
        guard let pl = netPL else { return nil }
        let cost = entryPrice * quantity
        return cost > 0 ? pl / cost : nil
    }

    /// Initial risk amount from the stop, in currency.
    var riskAmount: Double? {
        guard let stop = stopPrice else { return nil }
        let perUnit = (entryPrice - stop) * direction.sign
        guard perUnit > 0 else { return nil }
        return perUnit * quantity
    }

    /// Realised R-multiple: net P/L divided by the initial risk.
    var rMultiple: Double? {
        guard let pl = netPL, let risk = riskAmount, risk > 0 else { return nil }
        return pl / risk
    }

    /// Planned reward:risk from target and stop.
    var plannedRR: Double? {
        guard let stop = stopPrice, let target = targetPrice else { return nil }
        let risk = (entryPrice - stop) * direction.sign
        let reward = (target - entryPrice) * direction.sign
        guard risk > 0, reward > 0 else { return nil }
        return reward / risk
    }

    var holdingInterval: TimeInterval? {
        guard let exit = exitDate else { return nil }
        return exit.timeIntervalSince(entryDate)
    }
}
