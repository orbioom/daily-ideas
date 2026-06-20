import Foundation

enum GridSize: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var columns: Int {
        switch self {
        case .easy: return 4
        case .medium: return 4
        case .hard: return 6
        }
    }

    var rows: Int {
        switch self {
        case .easy: return 4
        case .medium: return 5
        case .hard: return 6
        }
    }

    var pairs: Int {
        switch self {
        case .easy: return 8
        case .medium: return 10
        case .hard: return 18
        }
    }

    var isPro: Bool {
        self == .hard
    }

    var displayDescription: String {
        switch self {
        case .easy: return "4×4 · 8 pairs"
        case .medium: return "4×5 · 10 pairs"
        case .hard: return "6×6 · 18 pairs"
        }
    }
}
