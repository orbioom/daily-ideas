import Foundation
import SwiftData

/// Seeds 1–2 sample children with ~12 measurements each plus some achieved milestones and
/// given vaccines, so the app is rich on first run and in previews. Gated by `didSeed`.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        // Don't double-seed if children already exist.
        let count = (try? context.fetchCount(FetchDescriptor<Child>())) ?? 0
        if count == 0 {
            insertSampleChildren(context: context)
        }
        didSeed = true
    }

    /// Two sample children: an 11-month boy and a ~3-year girl, each with a measurement history
    /// tracking near a sensible percentile, plus achieved milestones/vaccines for their age.
    static func insertSampleChildren(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        // --- Child 1: Theo, boy, ~11 months old ---
        if let theoBirth = cal.date(byAdding: .month, value: -11, to: now) {
            let theo = Child(name: "Theo", birthDate: theoBirth, sex: .male, colorHex: "5B91C9")
            context.insert(theo)
            seedMeasurements(for: theo, context: context,
                             targetWeightZ: 0.4, targetHeightZ: 0.2, targetHeadZ: 0.1, count: 12)
            achieveMilestonesUpTo(ageMonths: 9, for: theo, context: context)
            giveVaccinesUpTo(ageMonths: 9, for: theo, context: context)
        }

        // --- Child 2: Mara, girl, ~37 months old ---
        if let maraBirth = cal.date(byAdding: .month, value: -37, to: now) {
            let mara = Child(name: "Mara", birthDate: maraBirth, sex: .female, colorHex: "E08AA0")
            context.insert(mara)
            seedMeasurements(for: mara, context: context,
                             targetWeightZ: -0.3, targetHeightZ: 0.1, targetHeadZ: -0.2, count: 12)
            achieveMilestonesUpTo(ageMonths: 30, for: mara, context: context)
            giveVaccinesUpTo(ageMonths: 24, for: mara, context: context)
        }

        try? context.save()
    }

    /// Generate `count` measurements spread from birth to now, each sitting near the given z-scores
    /// (so the seeded child tracks a believable, slightly noisy percentile band).
    private static func seedMeasurements(for child: Child,
                                         context: ModelContext,
                                         targetWeightZ: Double,
                                         targetHeightZ: Double,
                                         targetHeadZ: Double,
                                         count: Int) {
        var rng = SplitMix64(seed: child.name.hashValueStable)
        let cal = Calendar.current
        let totalMonths = max(1, child.ageMonths())

        for i in 0..<count {
            // Spread visit ages from ~0.5 month to current age.
            let frac = Double(i) / Double(max(1, count - 1))
            let visitMonths = max(0.2, Double(totalMonths) * frac)
            guard let date = cal.date(byAdding: .day,
                                      value: Int(visitMonths * 30.4375),
                                      to: child.birthDate) else { continue }

            let noiseW = (rng.unit() - 0.5) * 0.5
            let noiseH = (rng.unit() - 0.5) * 0.5
            let noiseHd = (rng.unit() - 0.5) * 0.5

            let w = PercentileEngine.value(forZ: targetWeightZ + noiseW, measure: .weight, sex: child.sex, ageMonths: visitMonths)
            let h = PercentileEngine.value(forZ: targetHeightZ + noiseH, measure: .height, sex: child.sex, ageMonths: visitMonths)
            let hd = PercentileEngine.value(forZ: targetHeadZ + noiseHd, measure: .head, sex: child.sex, ageMonths: visitMonths)

            let m = GrowthMeasurement(date: date,
                                      weightKg: w.map { ($0 * 100).rounded() / 100 },
                                      heightCm: h.map { ($0 * 10).rounded() / 10 },
                                      headCm: hd.map { ($0 * 10).rounded() / 10 },
                                      note: i == 0 ? "Birth measurements" : nil,
                                      child: child)
            context.insert(m)
        }
    }

    private static func achieveMilestonesUpTo(ageMonths: Int, for child: Child, context: ModelContext) {
        let cal = Calendar.current
        for milestone in MilestoneCatalog.all where milestone.typicalAgeMonths <= ageMonths {
            let achievedDate = cal.date(byAdding: .month, value: milestone.typicalAgeMonths, to: child.birthDate)
            let record = MilestoneRecord(milestoneKey: milestone.key, achievedDate: achievedDate, child: child)
            context.insert(record)
        }
    }

    private static func giveVaccinesUpTo(ageMonths: Int, for child: Child, context: ModelContext) {
        let cal = Calendar.current
        for dose in VaccineCatalog.all where dose.recommendedAgeMonths <= ageMonths {
            let givenDate = cal.date(byAdding: .month, value: dose.recommendedAgeMonths, to: child.birthDate)
            let record = VaccineRecord(vaccineKey: dose.key, givenDate: givenDate, child: child)
            context.insert(record)
        }
    }

    /// Delete every child (cascades to their measurements/records) and reset.
    static func clearAll(context: ModelContext) {
        if let children = try? context.fetch(FetchDescriptor<Child>()) {
            for c in children { context.delete(c) }
        }
        try? context.save()
    }
}

private extension String {
    /// A stable, deterministic seed from a string (Swift's hashValue is randomized per run).
    var hashValueStable: UInt64 {
        var h: UInt64 = 1469598103934665603
        for byte in self.utf8 {
            h ^= UInt64(byte)
            h = h &* 1099511628211
        }
        return h
    }
}
