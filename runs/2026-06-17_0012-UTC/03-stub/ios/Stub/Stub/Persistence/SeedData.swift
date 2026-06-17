import Foundation
import SwiftData

/// Seeds two example scenarios on first run. Idempotent — checks a count first.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        var descriptor = FetchDescriptor<PayScenario>()
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let samples: [PayScenario] = [
            PayScenario(
                name: "Current Job — Austin",
                payType: .salary,
                payFrequency: .biweekly,
                filingStatus: .single,
                stateCode: "TX",
                rate: 0,
                hoursPerWeek: 40,
                annualSalary: 95_000,
                pretax401kPercent: 6,
                pretax401kDollar: 0,
                hsaAnnual: 2_000,
                healthPremiumPerPay: 120,
                otherPretaxPerPay: 0,
                postTaxPerPay: 0,
                extraWithholdingPerPay: 0
            ),
            PayScenario(
                name: "Offer — SF Startup",
                payType: .salary,
                payFrequency: .semimonthly,
                filingStatus: .single,
                stateCode: "CA",
                rate: 0,
                hoursPerWeek: 40,
                annualSalary: 128_000,
                pretax401kPercent: 4,
                pretax401kDollar: 0,
                hsaAnnual: 0,
                healthPremiumPerPay: 95,
                otherPretaxPerPay: 0,
                postTaxPerPay: 0,
                extraWithholdingPerPay: 0
            )
        ]

        for scenario in samples {
            context.insert(scenario)
        }
        try? context.save()
    }
}
