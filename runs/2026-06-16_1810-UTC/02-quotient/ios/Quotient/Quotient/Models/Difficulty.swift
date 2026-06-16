import Foundation

/// Difficulty tiers map to grid size and cage-shape distribution.
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .expert: return "Expert"
        }
    }

    /// Grid order N (N×N).
    var size: Int {
        switch self {
        case .easy:   return 4
        case .medium: return 5
        case .hard:   return 6
        case .expert: return 7
        }
    }

    /// Whether this tier requires Quotient Pro (6×6 and 7×7).
    var requiresPro: Bool {
        switch self {
        case .easy, .medium: return false
        case .hard, .expert: return true
        }
    }

    var subtitle: String {
        "\(size)×\(size) grid"
    }

    var systemImage: String {
        switch self {
        case .easy:   return "leaf"
        case .medium: return "flame"
        case .hard:   return "bolt"
        case .expert: return "crown"
        }
    }

    /// For the daily, difficulty rotates by weekday for variety.
    static func daily(for date: Date) -> Difficulty {
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: date)
        switch weekday {
        case 1, 7: return .hard      // weekends: a tougher puzzle
        case 2, 4: return .easy
        default:   return .medium
        }
    }
}
