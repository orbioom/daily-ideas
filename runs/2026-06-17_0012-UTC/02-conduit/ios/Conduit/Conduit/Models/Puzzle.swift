import Foundation

/// One color's endpoint pair plus its full reference solution path.
/// `solution` runs from `p1` to `p2` inclusive and is used ONLY for Hint and validation.
struct ColorPair: Identifiable, Sendable {
    let color: PipeColor
    let solution: [Cell]

    var id: Int { color.rawValue }
    var p1: Cell { solution.first ?? Cell(0, 0) }
    var p2: Cell { solution.last ?? Cell(0, 0) }
}

/// Packs group puzzles by difficulty. Master / Mind-bender require Pro.
enum PackID: String, CaseIterable, Identifiable, Sendable {
    case starter
    case classic
    case tricky
    case master
    case mindbender

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starter:    return "Starter"
        case .classic:    return "Classic"
        case .tricky:     return "Tricky"
        case .master:     return "Master"
        case .mindbender: return "Mind-bender"
        }
    }

    var subtitle: String {
        switch self {
        case .starter:    return "5×5 · ease in"
        case .classic:    return "6×6 · warm up"
        case .tricky:     return "7×7 · think ahead"
        case .master:     return "8×8 · for experts"
        case .mindbender: return "9×9 · the hardest"
        }
    }

    var size: Int {
        switch self {
        case .starter:    return 5
        case .classic:    return 6
        case .tricky:     return 7
        case .master:     return 8
        case .mindbender: return 9
        }
    }

    /// Whether the pack is locked behind Conduit Pro.
    var requiresPro: Bool {
        switch self {
        case .master, .mindbender: return true
        default:                   return false
        }
    }

    var symbol: String {
        switch self {
        case .starter:    return "leaf"
        case .classic:    return "square.grid.2x2"
        case .tricky:     return "square.grid.3x3"
        case .master:     return "crown"
        case .mindbender: return "brain.head.profile"
        }
    }
}

/// A complete puzzle definition. Pure value type — no UI, no persistence.
struct Puzzle: Identifiable, Sendable {
    let id: String
    let packId: PackID
    let size: Int
    let name: String
    let pairs: [ColorPair]

    /// The full set of cells touched by all solution paths.
    var totalCells: Int { size * size }

    /// All endpoint cells (two per color).
    var endpoints: [(color: PipeColor, cell: Cell)] {
        var out: [(PipeColor, Cell)] = []
        for pair in pairs {
            out.append((pair.color, pair.p1))
            out.append((pair.color, pair.p2))
        }
        return out
    }
}
