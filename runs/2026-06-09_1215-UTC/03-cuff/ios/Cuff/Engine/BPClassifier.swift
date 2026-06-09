import SwiftUI

/// The American Heart Association blood-pressure stages. Pure presentation +
/// classification — no SwiftData, no side effects.
enum BPCategory: String, CaseIterable, Identifiable, Codable {
    case normal, elevated, stage1, stage2, crisis

    var id: String { rawValue }

    var label: String {
        switch self {
        case .normal:   return "Normal"
        case .elevated: return "Elevated"
        case .stage1:   return "Stage 1"
        case .stage2:   return "Stage 2"
        case .crisis:   return "Crisis"
        }
    }

    /// A Brand color token so light + dark both stay legible.
    var color: Color {
        switch self {
        case .normal:   return Brand.live
        case .elevated: return Brand.warn
        case .stage1:   return Brand.warn
        case .stage2:   return Brand.danger
        case .crisis:   return Brand.danger
        }
    }

    /// Plain-language range, e.g. for legends and the report.
    var rangeDescription: String {
        switch self {
        case .normal:   return "Below 120 / 80"
        case .elevated: return "120–129 / below 80"
        case .stage1:   return "130–139 / 80–89"
        case .stage2:   return "140+ / 90+"
        case .crisis:   return "Above 180 / 120"
        }
    }

    /// Increasing severity index, used to pick the worse of two findings.
    var severity: Int {
        switch self {
        case .normal:   return 0
        case .elevated: return 1
        case .stage1:   return 2
        case .stage2:   return 3
        case .crisis:   return 4
        }
    }
}

enum BPClassifier {
    /// AHA classification. Uses the higher-severity finding between the systolic
    /// and diastolic columns. A reading with no values returns `.normal`.
    static func classify(systolic: Int, diastolic: Int) -> BPCategory {
        guard systolic > 0 || diastolic > 0 else { return .normal }

        let sysCat: BPCategory
        if systolic > 180 { sysCat = .crisis }
        else if systolic >= 140 { sysCat = .stage2 }
        else if systolic >= 130 { sysCat = .stage1 }
        else if systolic >= 120 { sysCat = .elevated }
        else { sysCat = .normal }

        let diaCat: BPCategory
        if diastolic > 120 { diaCat = .crisis }
        else if diastolic >= 90 { diaCat = .stage2 }
        else if diastolic >= 80 { diaCat = .stage1 }
        else { diaCat = .normal }

        // Elevated requires systolic 120–129 AND diastolic < 80; if the diastolic
        // pushes it up, the diastolic column wins via the severity comparison.
        return sysCat.severity >= diaCat.severity ? sysCat : diaCat
    }
}
