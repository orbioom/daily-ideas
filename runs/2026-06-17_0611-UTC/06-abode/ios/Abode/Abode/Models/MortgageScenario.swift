import Foundation
import SwiftData

/// A saved mortgage scenario. Money is stored as `Double` for SwiftData and converted
/// to `Decimal` only inside the engine (`asLoanInput`). Schedule rows are computed on
/// demand and never persisted.
@Model
final class MortgageScenario {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    var homePrice: Double
    var downPayment: Double
    var annualRatePct: Double
    var termYears: Int
    var propertyTaxPct: Double
    var annualInsurance: Double
    var monthlyHOA: Double
    var extraMonthly: Double

    init(id: UUID = UUID(),
         name: String,
         createdAt: Date = Date(),
         homePrice: Double,
         downPayment: Double,
         annualRatePct: Double,
         termYears: Int,
         propertyTaxPct: Double,
         annualInsurance: Double,
         monthlyHOA: Double,
         extraMonthly: Double) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.homePrice = homePrice
        self.downPayment = downPayment
        self.annualRatePct = annualRatePct
        self.termYears = termYears
        self.propertyTaxPct = propertyTaxPct
        self.annualInsurance = annualInsurance
        self.monthlyHOA = monthlyHOA
        self.extraMonthly = extraMonthly
    }

    /// Bridges the stored Double fields into a validated, Decimal `LoanInput`.
    var asLoanInput: LoanInput {
        LoanInput.make(
            homePrice: Decimal(homePrice),
            downPayment: Decimal(downPayment),
            annualRatePct: Decimal(annualRatePct),
            termYears: termYears,
            propertyTaxPct: Decimal(propertyTaxPct),
            annualInsurance: Decimal(annualInsurance),
            monthlyHOA: Decimal(monthlyHOA),
            extraMonthly: Decimal(extraMonthly)
        )
    }
}
