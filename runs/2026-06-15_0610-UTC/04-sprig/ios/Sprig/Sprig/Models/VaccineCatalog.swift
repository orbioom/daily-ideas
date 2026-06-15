import Foundation

/// One dose in the immunization schedule. `recommendedAgeMonths` is the earliest routine age.
struct VaccineDose: Identifiable {
    let key: String
    let name: String
    let series: String          // e.g. "DTaP", "MMR" — groups doses of the same vaccine
    let doseLabel: String       // e.g. "1st dose", "Birth dose"
    let recommendedAgeMonths: Int

    var id: String { key }

    var band: AgeBand { AgeBand.band(forMonths: max(recommendedAgeMonths, 1)) }
}

/// Status of a dose relative to the child's age and whether it's been given.
enum VaccineStatus {
    case given
    case upcoming     // recommended age is in the future
    case due          // recommended age reached recently, within the catch-up window
    case overdue      // well past the recommended age and not given

    var title: String {
        switch self {
        case .given:    return "Given"
        case .upcoming: return "Upcoming"
        case .due:      return "Due now"
        case .overdue:  return "Overdue"
        }
    }
}

/// Curated routine childhood immunization schedule (CDC-style), condensed to key doses 0–5y.
/// Informational only — always follow your pediatrician's plan.
enum VaccineCatalog {
    static let all: [VaccineDose] = [
        VaccineDose(key: "hepb.1", name: "Hepatitis B", series: "HepB", doseLabel: "Birth dose", recommendedAgeMonths: 0),
        VaccineDose(key: "hepb.2", name: "Hepatitis B", series: "HepB", doseLabel: "2nd dose", recommendedAgeMonths: 2),
        VaccineDose(key: "rv.1", name: "Rotavirus", series: "RV", doseLabel: "1st dose", recommendedAgeMonths: 2),
        VaccineDose(key: "dtap.1", name: "Diphtheria, Tetanus, Pertussis", series: "DTaP", doseLabel: "1st dose", recommendedAgeMonths: 2),
        VaccineDose(key: "hib.1", name: "Hib", series: "Hib", doseLabel: "1st dose", recommendedAgeMonths: 2),
        VaccineDose(key: "pcv.1", name: "Pneumococcal", series: "PCV13", doseLabel: "1st dose", recommendedAgeMonths: 2),
        VaccineDose(key: "ipv.1", name: "Polio", series: "IPV", doseLabel: "1st dose", recommendedAgeMonths: 2),

        VaccineDose(key: "rv.2", name: "Rotavirus", series: "RV", doseLabel: "2nd dose", recommendedAgeMonths: 4),
        VaccineDose(key: "dtap.2", name: "Diphtheria, Tetanus, Pertussis", series: "DTaP", doseLabel: "2nd dose", recommendedAgeMonths: 4),
        VaccineDose(key: "hib.2", name: "Hib", series: "Hib", doseLabel: "2nd dose", recommendedAgeMonths: 4),
        VaccineDose(key: "pcv.2", name: "Pneumococcal", series: "PCV13", doseLabel: "2nd dose", recommendedAgeMonths: 4),
        VaccineDose(key: "ipv.2", name: "Polio", series: "IPV", doseLabel: "2nd dose", recommendedAgeMonths: 4),

        VaccineDose(key: "hepb.3", name: "Hepatitis B", series: "HepB", doseLabel: "3rd dose", recommendedAgeMonths: 6),
        VaccineDose(key: "dtap.3", name: "Diphtheria, Tetanus, Pertussis", series: "DTaP", doseLabel: "3rd dose", recommendedAgeMonths: 6),
        VaccineDose(key: "pcv.3", name: "Pneumococcal", series: "PCV13", doseLabel: "3rd dose", recommendedAgeMonths: 6),
        VaccineDose(key: "ipv.3", name: "Polio", series: "IPV", doseLabel: "3rd dose", recommendedAgeMonths: 6),
        VaccineDose(key: "flu.1", name: "Influenza (yearly)", series: "Flu", doseLabel: "1st dose", recommendedAgeMonths: 6),

        VaccineDose(key: "mmr.1", name: "Measles, Mumps, Rubella", series: "MMR", doseLabel: "1st dose", recommendedAgeMonths: 12),
        VaccineDose(key: "var.1", name: "Varicella (chickenpox)", series: "VAR", doseLabel: "1st dose", recommendedAgeMonths: 12),
        VaccineDose(key: "hib.4", name: "Hib", series: "Hib", doseLabel: "Booster", recommendedAgeMonths: 12),
        VaccineDose(key: "pcv.4", name: "Pneumococcal", series: "PCV13", doseLabel: "Booster", recommendedAgeMonths: 12),
        VaccineDose(key: "hepa.1", name: "Hepatitis A", series: "HepA", doseLabel: "1st dose", recommendedAgeMonths: 12),

        VaccineDose(key: "dtap.4", name: "Diphtheria, Tetanus, Pertussis", series: "DTaP", doseLabel: "4th dose", recommendedAgeMonths: 15),
        VaccineDose(key: "hepa.2", name: "Hepatitis A", series: "HepA", doseLabel: "2nd dose", recommendedAgeMonths: 18),

        VaccineDose(key: "dtap.5", name: "Diphtheria, Tetanus, Pertussis", series: "DTaP", doseLabel: "5th dose", recommendedAgeMonths: 48),
        VaccineDose(key: "ipv.4", name: "Polio", series: "IPV", doseLabel: "4th dose", recommendedAgeMonths: 48),
        VaccineDose(key: "mmr.2", name: "Measles, Mumps, Rubella", series: "MMR", doseLabel: "2nd dose", recommendedAgeMonths: 48),
        VaccineDose(key: "var.2", name: "Varicella (chickenpox)", series: "VAR", doseLabel: "2nd dose", recommendedAgeMonths: 48)
    ]

    static let byKey: [String: VaccineDose] = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })

    /// Doses grouped by age band, in band order, each sorted by recommended age then name.
    static var byBand: [(band: AgeBand, items: [VaccineDose])] {
        AgeBand.allCases.compactMap { band in
            let items = all.filter { $0.band == band }
                .sorted { ($0.recommendedAgeMonths, $0.name) < ($1.recommendedAgeMonths, $1.name) }
            return items.isEmpty ? nil : (band, items)
        }
    }

    /// Compute a dose's status. `overdueGraceMonths` is how long after the recommended age a dose
    /// stays merely "due" before it becomes "overdue".
    static func status(childAgeMonths: Int, dose: VaccineDose, given: Bool, overdueGraceMonths: Int = 2) -> VaccineStatus {
        if given { return .given }
        if childAgeMonths < dose.recommendedAgeMonths { return .upcoming }
        if childAgeMonths <= dose.recommendedAgeMonths + overdueGraceMonths { return .due }
        return .overdue
    }
}
