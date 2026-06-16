import Foundation
import SwiftData

/// A saved snapshot of estimate inputs, so users can compare "what if" scenarios.
@Model
final class TaxScenario {
    @Attribute(.unique) var id: UUID
    var name: String
    var year: Int
    var filingStatusRaw: String
    var selfEmploymentIncome: Double
    var businessExpenses: Double
    var otherW2Income: Double
    var federalWithholding: Double
    var stateRatePct: Double
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         year: Int,
         filingStatusRaw: String,
         selfEmploymentIncome: Double,
         businessExpenses: Double,
         otherW2Income: Double,
         federalWithholding: Double,
         stateRatePct: Double,
         notes: String = "",
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.year = year
        self.filingStatusRaw = filingStatusRaw
        self.selfEmploymentIncome = selfEmploymentIncome
        self.businessExpenses = businessExpenses
        self.otherW2Income = otherW2Income
        self.federalWithholding = federalWithholding
        self.stateRatePct = stateRatePct
        self.notes = notes
        self.createdAt = createdAt
    }

    var filingStatus: FilingStatus {
        FilingStatus(rawValue: filingStatusRaw) ?? .single
    }

    /// Build engine inputs from the stored snapshot.
    var inputs: TaxInputs {
        TaxInputs(
            year: year,
            filingStatus: filingStatus,
            selfEmploymentIncome: Decimal(selfEmploymentIncome),
            businessExpenses: Decimal(businessExpenses),
            otherW2Income: Decimal(otherW2Income),
            federalWithholding: Decimal(federalWithholding),
            stateRatePct: Decimal(stateRatePct)
        )
    }

    var estimate: TaxEstimate { TaxEngine.estimate(inputs) }
}
