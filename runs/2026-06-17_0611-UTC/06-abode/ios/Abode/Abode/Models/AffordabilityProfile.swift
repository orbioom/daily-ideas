import Foundation
import SwiftData

/// Optionally-saved affordability inputs so a user can revisit a what-if.
@Model
final class AffordabilityProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    var grossMonthlyIncome: Double
    var monthlyDebts: Double
    var downPayment: Double
    var annualRatePct: Double
    var termYears: Int
    var frontEndDTIPct: Double   // e.g. 28
    var backEndDTIPct: Double    // e.g. 36
    var propertyTaxPct: Double
    var annualInsurance: Double
    var monthlyHOA: Double

    init(id: UUID = UUID(),
         name: String,
         createdAt: Date = Date(),
         grossMonthlyIncome: Double,
         monthlyDebts: Double,
         downPayment: Double,
         annualRatePct: Double,
         termYears: Int,
         frontEndDTIPct: Double,
         backEndDTIPct: Double,
         propertyTaxPct: Double,
         annualInsurance: Double,
         monthlyHOA: Double) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.grossMonthlyIncome = grossMonthlyIncome
        self.monthlyDebts = monthlyDebts
        self.downPayment = downPayment
        self.annualRatePct = annualRatePct
        self.termYears = termYears
        self.frontEndDTIPct = frontEndDTIPct
        self.backEndDTIPct = backEndDTIPct
        self.propertyTaxPct = propertyTaxPct
        self.annualInsurance = annualInsurance
        self.monthlyHOA = monthlyHOA
    }
}
