import SwiftUI

/// Difficulty tiers for a trick or command.
enum Difficulty: Int, CaseIterable, Identifiable, Comparable {
    case beginner = 1, easy = 2, intermediate = 3, advanced = 4

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .easy: return "Easy"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    var color: Color {
        switch self {
        case .beginner: return Theme.good
        case .easy: return Theme.accent
        case .intermediate: return Theme.warn
        case .advanced: return Theme.bad
        }
    }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Trick categories used for browsing/filtering.
enum TrickCategory: String, CaseIterable, Identifiable {
    case basics = "Basics"
    case manners = "Manners"
    case tricks = "Tricks"
    case advanced = "Agility & Advanced"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .basics: return "graduationcap.fill"
        case .manners: return "hand.raised.fill"
        case .tricks: return "sparkles"
        case .advanced: return "figure.run"
        }
    }
}

/// A static, code-defined trick. NOT a SwiftData model — the catalog is fixed content.
struct Trick: Identifiable, Hashable {
    let id: String
    let name: String
    let category: TrickCategory
    let difficulty: Difficulty
    let icon: String
    let summary: String
    let steps: [String]
    let tips: [String]
    let estimatedDays: Int
    let prerequisites: [String]

    static func == (lhs: Trick, rhs: Trick) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
