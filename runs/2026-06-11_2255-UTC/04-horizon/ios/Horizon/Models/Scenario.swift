import Foundation
import SwiftData

@Model
final class Scenario {
    var name: String
    var currentAge: Int
    /// Age at which the user wants the option to stop working.
    var targetRetirementAge: Int
    var currentInvested: Double
    var monthlyContribution: Double
    /// Expected annual nominal return, percent (e.g. 7.0).
    var expectedReturnPct: Double
    /// Expected annual inflation, percent (e.g. 2.5).
    var inflationPct: Double
    /// Planned annual spending in retirement, today's money.
    var annualSpending: Double
    /// Safe withdrawal rate, percent (e.g. 4.0).
    var swrPct: Double
    var isPrimary: Bool
    var createdAt: Date

    init(name: String, currentAge: Int = 30, targetRetirementAge: Int = 60,
         currentInvested: Double = 50_000, monthlyContribution: Double = 1_000,
         expectedReturnPct: Double = 7.0, inflationPct: Double = 2.5,
         annualSpending: Double = 40_000, swrPct: Double = 4.0,
         isPrimary: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.currentAge = currentAge
        self.targetRetirementAge = targetRetirementAge
        self.currentInvested = currentInvested
        self.monthlyContribution = monthlyContribution
        self.expectedReturnPct = expectedReturnPct
        self.inflationPct = inflationPct
        self.annualSpending = annualSpending
        self.swrPct = swrPct
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}
