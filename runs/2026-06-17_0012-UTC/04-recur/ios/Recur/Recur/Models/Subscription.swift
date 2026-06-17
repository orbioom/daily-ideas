import Foundation
import SwiftData

/// A tracked subscription or recurring payment. Money is persisted as `Double`
/// but all financial math is performed in `Decimal` (see `costDecimal`).
@Model
final class Subscription {
    /// Stable identity used by `Identifiable` / lists / charts.
    @Attribute(.unique) var id: UUID

    var name: String
    /// Per-charge cost (one cycle's price), persisted as Double, used as Decimal.
    var costAmount: Double
    var currencyCode: String

    /// Billing cadence token + custom day count (see `BillingCycle`).
    var cycleRaw: String
    var customDays: Int

    /// The date of the first / anchor charge. Renewals step forward from here.
    var firstBillingDate: Date

    var categoryRaw: String
    var colorHex: String
    var iconName: String

    var isTrial: Bool
    var trialEndDate: Date?

    var paymentMethod: String
    var notes: String

    var isActive: Bool
    var cancelledDate: Date?

    var createdAt: Date

    /// Logged price changes (newest interesting for the sparkline).
    @Relationship(deleteRule: .cascade, inverse: \PriceChange.subscription)
    var priceChanges: [PriceChange]

    init(id: UUID = UUID(),
         name: String,
         costAmount: Double,
         currencyCode: String = "USD",
         cycle: BillingCycle = .monthly,
         firstBillingDate: Date = Date(),
         category: SubCategory = .other,
         colorHex: String? = nil,
         iconName: String? = nil,
         isTrial: Bool = false,
         trialEndDate: Date? = nil,
         paymentMethod: String = "",
         notes: String = "",
         isActive: Bool = true,
         cancelledDate: Date? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.costAmount = max(0, costAmount)
        self.currencyCode = currencyCode
        self.cycleRaw = cycle.token
        if case let .customDays(d) = cycle { self.customDays = max(1, d) } else { self.customDays = 30 }
        self.firstBillingDate = firstBillingDate
        self.categoryRaw = category.rawValue
        self.colorHex = colorHex ?? category.defaultHex
        self.iconName = iconName ?? category.symbol
        self.isTrial = isTrial
        self.trialEndDate = trialEndDate
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.isActive = isActive
        self.cancelledDate = cancelledDate
        self.createdAt = createdAt
        self.priceChanges = []
    }

    // MARK: - Computed convenience (not persisted)

    /// The per-charge cost as a precise Decimal.
    var costDecimal: Decimal {
        Decimal(string: String(costAmount)) ?? Decimal(costAmount)
    }

    /// The reconstructed billing cycle.
    var cycle: BillingCycle {
        BillingCycle.from(token: cycleRaw, customDays: customDays)
    }

    /// The reconstructed category.
    var category: SubCategory {
        SubCategory.from(raw: categoryRaw)
    }

    /// Monthly-equivalent cost.
    var monthlyEquivalent: Decimal {
        CostEngine.monthlyEquivalent(amount: costDecimal, cycle: cycle)
    }

    /// Annual-equivalent cost.
    var annualEquivalent: Decimal {
        CostEngine.annualEquivalent(amount: costDecimal, cycle: cycle)
    }

    /// True when this counts toward the active monthly spend (active & not a trial).
    var isBillingNow: Bool {
        isActive && !isTrial
    }
}
