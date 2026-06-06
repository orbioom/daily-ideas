import Foundation

/// The kind of climbing a climb or attempt belongs to. Determines which grade
/// family (boulder vs route) is used and how grades are displayed.
enum Discipline: String, CaseIterable, Identifiable, Codable {
    case boulder
    case sport
    case topRope
    case trad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boulder: return "Boulder"
        case .sport:   return "Sport"
        case .topRope: return "Top-Rope"
        case .trad:    return "Trad"
        }
    }

    var symbol: String {
        switch self {
        case .boulder: return "cube"
        case .sport:   return "figure.climbing"
        case .topRope: return "arrow.up.to.line"
        case .trad:    return "link"
        }
    }

    /// Boulders use the V / Font families; routes use the YDS / French families.
    var isBoulder: Bool { self == .boulder }

    /// The grade family this discipline grades against.
    var family: GradeFamily { isBoulder ? .boulder : .route }
}
