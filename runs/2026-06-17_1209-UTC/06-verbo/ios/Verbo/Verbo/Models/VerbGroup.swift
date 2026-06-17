import Foundation

/// Conjugation group, by infinitive ending.
enum VerbGroup: String, CaseIterable, Identifiable, Codable {
    case ar    // Spanish -ar
    case er    // Spanish -er / French -er
    case ir    // Spanish -ir / French -ir
    case re    // French -re

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ar: return "-ar"
        case .er: return "-er"
        case .ir: return "-ir"
        case .re: return "-re"
        }
    }
}
