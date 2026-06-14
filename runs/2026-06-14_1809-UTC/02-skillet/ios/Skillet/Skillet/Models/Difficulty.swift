import SwiftUI

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .easy: return "gauge.with.dots.needle.0percent"
        case .medium: return "gauge.with.dots.needle.50percent"
        case .hard: return "gauge.with.dots.needle.100percent"
        }
    }

    var color: Color {
        switch self {
        case .easy: return Theme.good
        case .medium: return Theme.warn
        case .hard: return Theme.bad
        }
    }
}
