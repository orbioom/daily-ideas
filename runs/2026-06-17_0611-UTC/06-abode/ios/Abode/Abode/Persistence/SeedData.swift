import Foundation
import SwiftData

/// Seeds a couple of illustrative scenarios on first launch so Scenarios isn't empty.
/// Idempotent: checks the existing count first and never duplicates.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<MortgageScenario>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let samples: [MortgageScenario] = [
            MortgageScenario(
                name: "Starter — 30yr",
                homePrice: 320_000, downPayment: 64_000, annualRatePct: 6.5,
                termYears: 30, propertyTaxPct: 1.1, annualInsurance: 1_400,
                monthlyHOA: 0, extraMonthly: 0
            ),
            MortgageScenario(
                name: "Condo — 15yr",
                homePrice: 410_000, downPayment: 82_000, annualRatePct: 6.0,
                termYears: 15, propertyTaxPct: 1.25, annualInsurance: 1_100,
                monthlyHOA: 280, extraMonthly: 0
            )
        ]
        for s in samples { context.insert(s) }
        try? context.save()
    }
}
