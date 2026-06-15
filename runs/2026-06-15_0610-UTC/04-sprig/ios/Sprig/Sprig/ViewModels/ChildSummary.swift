import Foundation
import SwiftUI

/// A computed snapshot for a child, used on the Home list and detail hub. Computed in Swift
/// (not in a SwiftData predicate) from the child's measurements/records.
struct ChildSummary {
    let child: Child
    let ageDescription: String
    let ageMonths: Int

    /// Latest percentile per measure (nil if no measurement of that kind exists).
    let weightPercentile: PercentileResult?
    let heightPercentile: PercentileResult?
    let headPercentile: PercentileResult?

    let measurementCount: Int

    /// The next not-yet-achieved milestone whose typical age is nearest the child's age.
    let nextMilestone: Milestone?

    /// The next due-or-overdue vaccine dose, if any.
    let nextVaccine: VaccineDose?
    let nextVaccineStatus: VaccineStatus?

    let overdueVaccineCount: Int

    static func build(for child: Child) -> ChildSummary {
        let now = Date()
        let ageMonths = child.ageMonths(asOf: now)
        let latest = child.latestMeasurement

        func percentile(_ measure: GrowthMeasure) -> PercentileResult? {
            guard let m = latest, let value = m.value(for: measure) else { return nil }
            let age = child.ageMonthsExact(asOf: m.date)
            return PercentileEngine.evaluate(value: value, measure: measure, sex: child.sex, ageMonths: age)
        }

        // Next milestone: lowest typicalAge among not-yet-achieved, preferring overdue/near.
        let achievedKeys = Set(child.milestoneRecords.filter { $0.isAchieved }.map { $0.milestoneKey })
        let pending = MilestoneCatalog.all
            .filter { !achievedKeys.contains($0.key) }
            .sorted { $0.typicalAgeMonths < $1.typicalAgeMonths }
        let nextMilestone = pending.first { $0.typicalAgeMonths >= ageMonths } ?? pending.first

        // Vaccines: status per dose.
        let givenKeys = Set(child.vaccineRecords.filter { $0.isGiven }.map { $0.vaccineKey })
        var overdue = 0
        var nextDose: VaccineDose?
        var nextStatus: VaccineStatus?
        for dose in VaccineCatalog.all {
            let given = givenKeys.contains(dose.key)
            let status = VaccineCatalog.status(childAgeMonths: ageMonths, dose: dose, given: given)
            if status == .overdue { overdue += 1 }
            if !given, status == .overdue || status == .due {
                if nextDose == nil || dose.recommendedAgeMonths < (nextDose?.recommendedAgeMonths ?? .max) {
                    nextDose = dose
                    nextStatus = status
                }
            }
        }
        if nextDose == nil {
            // Otherwise surface the soonest upcoming dose.
            let upcoming = VaccineCatalog.all
                .filter { !givenKeys.contains($0.key) && $0.recommendedAgeMonths > ageMonths }
                .sorted { $0.recommendedAgeMonths < $1.recommendedAgeMonths }
            nextDose = upcoming.first
            nextStatus = nextDose.map { _ in VaccineStatus.upcoming }
        }

        return ChildSummary(
            child: child,
            ageDescription: child.ageDescription(asOf: now),
            ageMonths: ageMonths,
            weightPercentile: percentile(.weight),
            heightPercentile: percentile(.height),
            headPercentile: percentile(.head),
            measurementCount: child.measurements.count,
            nextMilestone: nextMilestone,
            nextVaccine: nextDose,
            nextVaccineStatus: nextStatus,
            overdueVaccineCount: overdue
        )
    }

    func percentile(for measure: GrowthMeasure) -> PercentileResult? {
        switch measure {
        case .weight: return weightPercentile
        case .height: return heightPercentile
        case .head:   return headPercentile
        }
    }
}

/// Child accent color palette presented when creating/editing a child.
enum ChildColors {
    static let palette: [String] = ["3F9D6B", "5B91C9", "E08AA0", "CB8B2E", "8E6FC9", "C8553A"]

    static func color(hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let value = UInt(cleaned, radix: 16) else { return Theme.accent }
        return Color(hex: value)
    }
}
