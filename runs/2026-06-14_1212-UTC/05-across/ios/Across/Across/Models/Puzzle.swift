import Foundation

/// Difficulty tag for a puzzle.
enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var sortRank: Int {
        switch self {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 2
        }
    }
}

/// One clue keyed to a derived slot.
struct Clue {
    let number: Int
    let direction: Direction
    let text: String

    /// Matches CrosswordEngine slot ids.
    var slotID: String { "\(number)-\(direction.rawValue)" }
}

/// An authored puzzle: a solution grid + per-slot clues + metadata. The engine
/// derives numbering/slots/answers; clues are looked up by slot id at runtime.
struct Puzzle: Identifiable {
    let id: String          // stable id, e.g. "mini-001"
    let title: String
    let difficulty: Difficulty
    /// Row-major solution rows; '#' = block, A–Z letters otherwise.
    let grid: [String]
    /// Across clues, keyed implicitly by number.
    let acrossClues: [Int: String]
    /// Down clues, keyed implicitly by number.
    let downClues: [Int: String]

    /// Grid side length (assumes square; engine validates rectangularity anyway).
    var size: Int { grid.count }

    /// "Mini" (5x5 and smaller) vs "Midi" (larger).
    var kindLabel: String { size <= 5 ? "Mini" : "Midi" }

    /// Build the engine for this puzzle (nil if the grid is malformed).
    func makeEngine() -> CrosswordEngine? { CrosswordEngine(grid: grid) }

    /// Clue text for a given slot, with a graceful fallback.
    func clue(for slot: Slot) -> String {
        switch slot.direction {
        case .across: return acrossClues[slot.number] ?? "—"
        case .down: return downClues[slot.number] ?? "—"
        }
    }
}
