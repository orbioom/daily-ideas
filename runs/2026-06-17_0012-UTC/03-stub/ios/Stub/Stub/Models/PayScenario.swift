import Foundation
import SwiftData

/// A saved pay scenario / job offer. Persisted in SwiftData.
/// Money is stored as `Double` for SwiftData compatibility and converted to
/// `Decimal` only at compute time. Enums are stored as their `rawValue` strings.
@Model
final class PayScenario {
    /// Stable identity.
    @Attribute(.unique) var id: UUID

    var name: String

    // Raw enum storage (rawValue strings)
    var payTypeRaw: String
    var payFrequencyRaw: String
    var filingStatusRaw: String
    var stateCode: String

    // Pay
    var rate: Double            // hourly $/hour
    var hoursPerWeek: Double
    var annualSalary: Double

    // Pre-tax
    var pretax401kPercent: Double   // 0...100 (a percentage, not a fraction)
    var pretax401kDollar: Double    // $/year
    var hsaAnnual: Double           // $/year
    var healthPremiumPerPay: Double // $ per paycheck
    var otherPretaxPerPay: Double   // $ per paycheck

    // Post-tax
    var postTaxPerPay: Double
    var extraWithholdingPerPay: Double

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        payType: PayType,
        payFrequency: PayFrequency,
        filingStatus: FilingStatus,
        stateCode: String,
        rate: Double,
        hoursPerWeek: Double,
        annualSalary: Double,
        pretax401kPercent: Double,
        pretax401kDollar: Double,
        hsaAnnual: Double,
        healthPremiumPerPay: Double,
        otherPretaxPerPay: Double,
        postTaxPerPay: Double,
        extraWithholdingPerPay: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.payTypeRaw = payType.rawValue
        self.payFrequencyRaw = payFrequency.rawValue
        self.filingStatusRaw = filingStatus.rawValue
        self.stateCode = stateCode
        self.rate = rate
        self.hoursPerWeek = hoursPerWeek
        self.annualSalary = annualSalary
        self.pretax401kPercent = pretax401kPercent
        self.pretax401kDollar = pretax401kDollar
        self.hsaAnnual = hsaAnnual
        self.healthPremiumPerPay = healthPremiumPerPay
        self.otherPretaxPerPay = otherPretaxPerPay
        self.postTaxPerPay = postTaxPerPay
        self.extraWithholdingPerPay = extraWithholdingPerPay
        self.createdAt = createdAt
    }
}

// MARK: - Computed enum accessors (default-safe)

extension PayScenario {
    var payType: PayType { PayType(rawValue: payTypeRaw) ?? .salary }
    var payFrequency: PayFrequency { PayFrequency(rawValue: payFrequencyRaw) ?? .biweekly }
    var filingStatus: FilingStatus { FilingStatus(rawValue: filingStatusRaw) ?? .single }
    var state: USState { StateTaxTable.state(forCode: stateCode) }

    /// Builds a validated engine input from this stored scenario.
    var input: PaycheckInput {
        PaycheckInput.make(
            payType: payType,
            hourlyRate: Decimal(rate),
            hoursPerWeek: Decimal(hoursPerWeek),
            annualSalary: Decimal(annualSalary),
            frequency: payFrequency,
            status: filingStatus,
            state: state,
            pretax401kPercent: Decimal(pretax401kPercent) / 100,   // % → fraction
            pretax401kDollar: Decimal(pretax401kDollar),
            hsaAnnual: Decimal(hsaAnnual),
            healthPremiumPerPay: Decimal(healthPremiumPerPay),
            otherPretaxPerPay: Decimal(otherPretaxPerPay),
            postTaxPerPay: Decimal(postTaxPerPay),
            extraWithholdingPerPay: Decimal(extraWithholdingPerPay)
        )
    }

    /// Convenience: compute the full result for this scenario.
    var result: PaycheckResult { PaycheckEngine.compute(input) }
}
