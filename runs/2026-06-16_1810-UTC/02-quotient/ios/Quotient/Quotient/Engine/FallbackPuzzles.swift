import Foundation

/// Hand-verified, uniquely-solvable puzzles used as a guaranteed fallback so
/// generation *always* returns a valid unique puzzle even in the (extremely
/// unlikely) event the seeded generator exhausts its retries.
enum FallbackPuzzles {

    /// A known-good 4×4 puzzle. Solution is a valid Latin square; cages were
    /// constructed from that solution so it is solvable by construction, and it
    /// has been verified unique by the bundled solver.
    ///
    /// Solution (row-major):
    /// 1 2 3 4
    /// 2 3 4 1
    /// 3 4 1 2
    /// 4 1 2 3
    static func fourByFour() -> Puzzle {
        let solution = [
            1, 2, 3, 4,
            2, 3, 4, 1,
            3, 4, 1, 2,
            4, 1, 2, 3
        ]
        // Cages partition all 16 cells exactly once.
        let cages: [Cage] = [
            // 1+2 = 3 (add)
            Cage(id: 0, cells: [0, 1], op: .add, target: 3),
            // 3,4 -> |3-4| = 1 (subtract)
            Cage(id: 1, cells: [2, 3], op: .subtract, target: 1),
            // 2,3,3 -> 2*3*3... use vertical: cells 4,8 = 2,3 -> sum 5
            Cage(id: 2, cells: [4, 8], op: .add, target: 5),
            // cells 5,6 = 3,4 -> 3*4 = 12 (multiply)
            Cage(id: 3, cells: [5, 6], op: .multiply, target: 12),
            // cells 7,11 = 1,2 -> 1*2 = 2 (multiply)
            Cage(id: 4, cells: [7, 11], op: .multiply, target: 2),
            // cells 9,10 = 4,1 -> 4/1 = 4 (divide)
            Cage(id: 5, cells: [9, 10], op: .divide, target: 4),
            // cells 12,13 = 4,1 -> 4/1 = 4 (divide)
            Cage(id: 6, cells: [12, 13], op: .divide, target: 4),
            // cells 14,15 = 2,3 -> sum 5 (add)
            Cage(id: 7, cells: [14, 15], op: .add, target: 5)
        ]
        return Puzzle(size: 4, solution: solution, cages: cages)
    }
}
