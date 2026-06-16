import Foundation

/// The arithmetic operation a cage enforces over its cells.
enum CageOp: String, Codable, CaseIterable, Hashable {
    case add
    case subtract
    case multiply
    case divide
    case given   // a single revealed cell

    /// Symbol shown next to the cage target.
    var symbol: String {
        switch self {
        case .add:      return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide:   return "÷"
        case .given:    return ""
        }
    }

    var accessibleName: String {
        switch self {
        case .add:      return "plus"
        case .subtract: return "minus"
        case .multiply: return "times"
        case .divide:   return "divided by"
        case .given:    return "given"
        }
    }
}

/// A cage: a set of cells that together must satisfy `op` with result `target`.
struct Cage: Codable, Identifiable, Hashable {
    var id: Int
    var cells: [Int]   // cell indices, row-major
    var op: CageOp
    var target: Int

    /// The top-left cell of the cage (smallest index) where the label is drawn.
    var labelCell: Int { cells.min() ?? cells.first ?? 0 }

    /// Human-readable label, e.g. "12+" or "3÷" or "5".
    var label: String {
        op == .given ? "\(target)" : "\(target)\(op.symbol)"
    }
}

/// A fully specified puzzle: its size, the unique solution, and the cages.
struct Puzzle: Codable, Hashable {
    var size: Int                 // 4...7
    var solution: [Int]           // row-major, values 1...size
    var cages: [Cage]

    var cellCount: Int { size * size }

    /// Maps each cell index to the id of the cage it belongs to.
    func cageIndexByCell() -> [Int] {
        var map = [Int](repeating: -1, count: cellCount)
        for cage in cages {
            for cell in cage.cells where cell >= 0 && cell < map.count {
                map[cell] = cage.id
            }
        }
        return map
    }

    func cage(forCell cell: Int) -> Cage? {
        cages.first { $0.cells.contains(cell) }
    }

    static func row(of index: Int, size: Int) -> Int { size > 0 ? index / size : 0 }
    static func col(of index: Int, size: Int) -> Int { size > 0 ? index % size : 0 }
    static func index(row: Int, col: Int, size: Int) -> Int { row * size + col }
}

/// Per-cell editable state held during play.
struct CellState: Codable, Hashable {
    var value: Int?
    var notes: Set<Int>

    init(value: Int? = nil, notes: Set<Int> = []) {
        self.value = value
        self.notes = notes
    }

    var isEmpty: Bool { value == nil && notes.isEmpty }
}
