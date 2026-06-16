import Foundation

/// The fully generated board for a puzzle.
struct WordSearchBoard {
    let size: Int
    /// Row-major grid of uppercase letters. Always `size` rows, each with `size` columns.
    let grid: [[Character]]
    /// Maps each successfully placed word to its ordered cell path.
    let placements: [String: [GridPoint]]

    /// The list of words that were actually placed (a subset of the requested words).
    var words: [String] { Array(placements.keys).sorted() }

    /// Safe character lookup; returns a space if the point is out of bounds.
    func letter(at point: GridPoint) -> Character {
        guard point.row >= 0, point.row < grid.count else { return " " }
        let row = grid[point.row]
        guard point.col >= 0, point.col < row.count else { return " " }
        return row[point.col]
    }
}

/// Pure, deterministic word-search generator.
/// Same inputs (words, size, directions, seed) always produce the same board.
struct WordSearchGenerator {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// Generates a board. Words that cannot be placed after repeated attempts are dropped
    /// gracefully, so the function never fails or hangs.
    static func generate(
        words rawWords: [String],
        size requestedSize: Int,
        directions: [Direction],
        targetCount: Int,
        seed: UInt64
    ) -> WordSearchBoard {
        // Guard the grid size to a sane range.
        let size = max(5, min(20, requestedSize))
        var rng = SeededRNG(seed: seed)

        // Normalize: uppercase, letters only, fits in the grid, de-duplicated.
        let cleaned = rawWords
            .map { sanitize($0) }
            .filter { !$0.isEmpty && $0.count <= size }
        var seen = Set<String>()
        var unique: [String] = []
        for word in cleaned where !seen.contains(word) {
            seen.insert(word)
            unique.append(word)
        }

        // Choose candidate words deterministically: shuffle, then prefer longer words first
        // so the hard-to-place words get the emptiest grid.
        let shuffled = rng.shuffled(unique)
        let ordered = shuffled.sorted { $0.count > $1.count }
        let desired = max(1, min(targetCount, ordered.count))

        // Use a sentinel empty marker so we can detect free cells.
        let empty: Character = " "
        var grid = [[Character]](repeating: [Character](repeating: empty, count: size), count: size)
        var placements: [String: [GridPoint]] = [:]
        let usableDirections = directions.isEmpty ? [Direction(dRow: 0, dCol: 1)] : directions

        var placedCount = 0
        for word in ordered {
            if placedCount >= desired { break }
            if placements[word] != nil { continue }
            if let path = tryPlace(word: word, grid: &grid, size: size, empty: empty, directions: usableDirections, rng: &rng) {
                placements[word] = path
                placedCount += 1
            }
            // If placement fails, the word is simply skipped (graceful reduction).
        }

        // Fill remaining empty cells with seeded random letters.
        for r in 0..<size {
            for c in 0..<size where grid[r][c] == empty {
                let idx = rng.int(upperBound: alphabet.count)
                grid[r][c] = alphabet[idx]
            }
        }

        return WordSearchBoard(size: size, grid: grid, placements: placements)
    }

    /// Attempts to place a single word, trying many random origins/directions.
    private static func tryPlace(
        word: String,
        grid: inout [[Character]],
        size: Int,
        empty: Character,
        directions: [Direction],
        rng: inout SeededRNG
    ) -> [GridPoint]? {
        let letters = Array(word)
        guard !letters.isEmpty, letters.count <= size else { return nil }

        let attempts = 200
        for _ in 0..<attempts {
            guard let dir = rng.pick(directions) else { return nil }
            // Pick a valid origin so the whole word stays in bounds for this direction.
            let lastRow = (letters.count - 1) * dir.dRow
            let lastCol = (letters.count - 1) * dir.dCol

            let rowLow = max(0, -lastRow)
            let rowHigh = min(size - 1, size - 1 - lastRow)
            let colLow = max(0, -lastCol)
            let colHigh = min(size - 1, size - 1 - lastCol)
            guard rowLow <= rowHigh, colLow <= colHigh else { continue }

            let startRow = rowLow + rng.int(upperBound: rowHigh - rowLow + 1)
            let startCol = colLow + rng.int(upperBound: colHigh - colLow + 1)

            // Check that the path is free or overlaps only on matching letters.
            var path: [GridPoint] = []
            var fits = true
            for i in 0..<letters.count {
                let r = startRow + i * dir.dRow
                let c = startCol + i * dir.dCol
                guard r >= 0, r < size, c >= 0, c < size else { fits = false; break }
                let existing = grid[r][c]
                if existing != empty && existing != letters[i] {
                    fits = false
                    break
                }
                path.append(GridPoint(r, c))
            }

            if fits, path.count == letters.count {
                for (i, point) in path.enumerated() {
                    grid[point.row][point.col] = letters[i]
                }
                return path
            }
        }
        return nil
    }

    /// Keeps only A–Z and uppercases.
    static func sanitize(_ raw: String) -> String {
        String(raw.uppercased().unicodeScalars.filter { $0.value >= 65 && $0.value <= 90 }.map { Character($0) })
    }
}
