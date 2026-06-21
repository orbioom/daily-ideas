import Foundation

struct CheckersMove {
    let from: (row: Int, col: Int)
    let to: (row: Int, col: Int)
    let captures: [(row: Int, col: Int)]

    var isJump: Bool { !captures.isEmpty }
}

extension CheckersMove: Equatable {
    static func == (lhs: CheckersMove, rhs: CheckersMove) -> Bool {
        guard lhs.from.row == rhs.from.row,
              lhs.from.col == rhs.from.col,
              lhs.to.row == rhs.to.row,
              lhs.to.col == rhs.to.col,
              lhs.captures.count == rhs.captures.count
        else { return false }

        for (l, r) in zip(lhs.captures, rhs.captures) {
            if l.row != r.row || l.col != r.col { return false }
        }
        return true
    }
}

extension CheckersMove: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(from.row)
        hasher.combine(from.col)
        hasher.combine(to.row)
        hasher.combine(to.col)
        for cap in captures {
            hasher.combine(cap.row)
            hasher.combine(cap.col)
        }
    }
}
