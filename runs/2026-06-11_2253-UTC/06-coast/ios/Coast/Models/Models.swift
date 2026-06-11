import Foundation
import SwiftData

/// The single financial-independence plan. App is single-profile (one household)
/// but modeled as an entity so future multi-scenario support is clean.
@Model
final class Profile {
    var currentAge: Double
    var annualExpenses: Double
    /// Current invested net worth (the portfolio working for you).
    var currentInvested: Double
    /// Annual amount you add to investments.
    var annualContribution: Double
    /// Expected real (inflation-adjusted) return, e.g. 0.05 for 5%.
    var realReturn: Double
    /// Safe withdrawal rate, e.g. 0.04 for the 4% rule.
    var withdrawalRate: Double
    var currencyCode: String
    var createdAt: Date

    init(currentAge: Double = 32, annualExpenses: Double = 45_000,
         currentInvested: Double = 60_000, annualContribution: Double = 24_000,
         realReturn: Double = 0.05, withdrawalRate: Double = 0.04,
         currencyCode: String = "USD") {
        self.currentAge = currentAge
        self.annualExpenses = annualExpenses
        self.currentInvested = currentInvested
        self.annualContribution = annualContribution
        self.realReturn = realReturn
        self.withdrawalRate = withdrawalRate
        self.currencyCode = currencyCode
        self.createdAt = Date()
    }

    /// The portfolio needed so that withdrawalRate × number covers expenses.
    var fiNumber: Double {
        guard withdrawalRate > 0 else { return 0 }
        return annualExpenses / withdrawalRate
    }
}

/// A point-in-time net-worth snapshot, for the progress chart.
@Model
final class NetWorthEntry {
    var date: Date
    var amount: Double
    var note: String

    init(date: Date = Date(), amount: Double, note: String = "") {
        self.date = date
        self.amount = amount
        self.note = note
    }
}

/// A milestone on the journey (auto-generated "Coast FI", "Half FI", custom goals).
@Model
final class Milestone {
    var title: String
    /// Portfolio value that unlocks this milestone.
    var targetAmount: Double
    var isAuto: Bool
    var emoji: String

    init(title: String, targetAmount: Double, isAuto: Bool = false, emoji: String = "🎯") {
        self.title = title
        self.targetAmount = targetAmount
        self.isAuto = isAuto
        self.emoji = emoji
    }
}
