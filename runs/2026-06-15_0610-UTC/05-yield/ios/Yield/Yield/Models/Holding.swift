import Foundation
import SwiftData

/// A single dividend-paying position the user holds. All money values are `Decimal`.
@Model
final class Holding {
    @Attribute(.unique) var id: UUID
    var ticker: String
    var name: String
    var shares: Decimal
    var avgCostPerShare: Decimal
    var annualDividendPerShare: Decimal
    /// Optional latest market price; only used for *current* yield (not income math).
    var currentPrice: Decimal?
    private var frequencyRaw: String
    private var payCycleRaw: String
    var payDayOfMonth: Int
    private var sectorRaw: String
    var account: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DividendPayment.holding)
    var payments: [DividendPayment]

    init(id: UUID = UUID(),
         ticker: String,
         name: String,
         shares: Decimal,
         avgCostPerShare: Decimal,
         annualDividendPerShare: Decimal,
         currentPrice: Decimal? = nil,
         frequency: DividendFrequency = .quarterly,
         payCycle: PayCycle = .cycle1,
         payDayOfMonth: Int = 15,
         sector: Sector = .other,
         account: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.ticker = ticker
        self.name = name
        self.shares = shares
        self.avgCostPerShare = avgCostPerShare
        self.annualDividendPerShare = annualDividendPerShare
        self.currentPrice = currentPrice
        self.frequencyRaw = frequency.rawValue
        self.payCycleRaw = payCycle.rawValue
        self.payDayOfMonth = payDayOfMonth
        self.sectorRaw = sector.rawValue
        self.account = account
        self.createdAt = createdAt
        self.payments = []
    }

    // MARK: Enum-backed accessors (raw stored, typed surfaced — safe defaults)

    var frequency: DividendFrequency {
        get { DividendFrequency(rawValue: frequencyRaw) ?? .quarterly }
        set { frequencyRaw = newValue.rawValue }
    }

    var payCycle: PayCycle {
        get { PayCycle(rawValue: payCycleRaw) ?? .cycle1 }
        set { payCycleRaw = newValue.rawValue }
    }

    var sector: Sector {
        get { Sector(rawValue: sectorRaw) ?? .other }
        set { sectorRaw = newValue.rawValue }
    }
}
