import Foundation

/// Biological sex used for reference-range selection. This is a clinical
/// parameter (not an identity statement) and drives which lab ranges apply.
enum BiologicalSex: String, CaseIterable, Identifiable, Codable {
    case female = "Female"
    case male = "Male"
    case unspecified = "Prefer not to say"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .female: return "F"
        case .male: return "M"
        case .unspecified: return "—"
        }
    }
}
