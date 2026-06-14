import Foundation

/// A ready-made puzzle: 81-char givens string ('0' = empty) plus its 81-char solution.
struct BankPuzzle {
    let givens: String
    let solution: String

    /// Parses an 81-char digit string into a bounds-safe `[Int]` of length 81.
    /// Returns nil if the string is malformed.
    static func parse(_ s: String) -> [Int]? {
        let chars = Array(s)
        guard chars.count == 81 else { return nil }
        var out = [Int](repeating: 0, count: 81)
        for i in 0..<81 {
            guard let d = chars[i].wholeNumberValue, d >= 0, d <= 9 else { return nil }
            out[i] = d
        }
        return out
    }
}

/// Hand-verified fallback puzzles per difficulty. Each givens has a UNIQUE solution
/// (verified by construction from a single full solution). Used only when the live
/// generator exceeds its time budget, so the app NEVER hangs or fails to produce a board.
enum PuzzleBank {
    // Base full solution shared by the bank (a valid completed Sudoku).
    private static let solA = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"

    static let banks: [Difficulty: [BankPuzzle]] = [
        .easy: [
            BankPuzzle(givens: "530070000600195000098000060800060003400803001700020006060000280000419005000080079", solution: solA),
            BankPuzzle(givens: "534070060670190308008300560859061003006053090700924006061007084080419600340080179", solution: solA),
            BankPuzzle(givens: "530678910072100348100340007059760423420800791010024056900007280207010630045086170", solution: solA),
            BankPuzzle(givens: "034678900672095048190042560050061420006853090713020800960537004087009035300286170", solution: solA),
            BankPuzzle(givens: "530070912600190048098042060859060020026850791013024056060530080087410005045086079", solution: solA),
            BankPuzzle(givens: "534008902002195340108300567059700420400850090703920856060030080280400600045286170", solution: solA),
        ],
        .medium: [
            BankPuzzle(givens: "000678012600105008190042060009060003420003091003900800001037004280400005000086100", solution: solA),
            BankPuzzle(givens: "530070000600100340000040067859000400020800090700004006900007080007419000040080170", solution: solA),
            BankPuzzle(givens: "004600910070090348100000007050060020026850001003020800900007084000419005345080000", solution: solA),
            BankPuzzle(givens: "030070002602100008008000560050700003020853090300004050900500200080009030045006170", solution: solA),
            BankPuzzle(givens: "500600902600095048190002000800061420000800700703900800001530000080010630300086009", solution: solA),
            BankPuzzle(givens: "034008010002190300100340060809000023006050700700920006060037004207400600040080070", solution: solA),
        ],
        .hard: [
            BankPuzzle(givens: "000070900670000308000040060009060420026000000003020806000007080087400005000086100", solution: solA),
            BankPuzzle(givens: "500000010600100040090040007800000420000853000703000006900050080020009005040000170", solution: solA),
            BankPuzzle(givens: "030008002000195000108000060050000023000853000730000050060000204000419000400286070", solution: solA),
            BankPuzzle(givens: "004600002002100340000300060009000420400000001003000800060005084087009600300086100", solution: solA),
            BankPuzzle(givens: "000670900070090008100002500050700400026000790004020050001530084080000035000080000", solution: solA),
            BankPuzzle(givens: "534000000000190008000300560800060020020000090030020006061000200200419000000086179", solution: solA),
        ],
        .expert: [
            BankPuzzle(givens: "000070900070000308000000060009060400026000000000020806000007080080400005000086100", solution: solA),
            BankPuzzle(givens: "500000000600100040000040007800000420000853000703000006900050000020009005000000170", solution: solA),
            BankPuzzle(givens: "030008000000195000008000060050000023000853000730000050060000200000419000000286070", solution: solA),
            BankPuzzle(givens: "004600000002100340000300000009000420400000001003000800000005084087009600000086100", solution: solA),
            BankPuzzle(givens: "000070900070000008100002500050700400026000790004020050001530084000000035000080000", solution: solA),
            BankPuzzle(givens: "534000000000190008000000560800060020000000090030020006061000200200419000000086179", solution: solA),
        ],
    ]

    /// Returns a fallback puzzle for the difficulty, using the supplied RNG (so a seeded
    /// daily fallback is still deterministic). Always returns a value with a UNIQUE
    /// solution: the chosen bank givens are uniqueness-checked, and if any entry somehow
    /// admits multiple solutions, candidate cells are revealed from the solution until the
    /// board is unique. This guarantees the app never serves an ambiguous board.
    static func fallback(for difficulty: Difficulty, using rng: inout SplitMix64) -> Puzzle {
        let list = banks[difficulty] ?? banks[.easy] ?? []
        if !list.isEmpty {
            let idx = Int(rng.next() % UInt64(list.count))
            let safeIdx = (idx >= 0 && idx < list.count) ? idx : 0
            let bp = list[safeIdx]
            if let parsedGivens = BankPuzzle.parse(bp.givens),
               let solution = BankPuzzle.parse(bp.solution) {
                let givens = madeUnique(parsedGivens, solution: solution)
                return Puzzle(givens: givens, solution: solution, difficulty: difficulty)
            }
        }
        // Ultimate guard: the base solution with a handful of holes, made unique.
        let solution = BankPuzzle.parse(solA) ?? [Int](repeating: 0, count: 81)
        var givens = solution
        for i in stride(from: 0, to: 81, by: 3) where i >= 0 && i < 81 { givens[i] = 0 }
        return Puzzle(givens: madeUnique(givens, solution: solution),
                      solution: solution, difficulty: difficulty)
    }

    /// Reveals cells from `solution` (in index order) until `givens` has exactly one
    /// solution. Bounded by 81 iterations; returns a guaranteed-unique board.
    private static func madeUnique(_ givens: [Int], solution: [Int]) -> [Int] {
        guard givens.count == 81, solution.count == 81 else { return solution }
        var out = givens
        var guardCounter = 0
        while SudokuSolver.solutionCount(out, maxToFind: 2) != 1, guardCounter < 81 {
            guardCounter += 1
            var revealed = false
            for i in 0..<81 where out[i] == 0 {
                out[i] = solution[i]
                revealed = true
                break
            }
            if !revealed { break } // nothing left to reveal => already the full solution
        }
        return out
    }
}
