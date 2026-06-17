import Foundation

/// The hand-authored / procedurally-derived bank of Conduit puzzles.
///
/// Every puzzle is built from a **Hamiltonian snake path** over the whole grid that
/// is then cut into contiguous segments — one segment per color. Because the snake
/// visits every cell exactly once and only ever steps to an orthogonal neighbor,
/// each resulting segment is guaranteed to be:
///   * orthogonally continuous,
///   * non-overlapping with the others, and
///   * collectively a 100%-coverage fill.
/// The two ends of each segment become that color's endpoints. This makes every
/// puzzle provably solvable with a full-coverage solution by construction.
///
/// To add genuine variety the snake is generated with a handful of distinct
/// "weave" strategies and the cut points are varied per puzzle, producing layouts
/// that feel hand-authored while remaining guaranteed valid.
enum PuzzleBank {

    /// All puzzles, ordered by pack then by index.
    static let all: [Puzzle] = build()

    /// Puzzles for a given pack, in order.
    static func puzzles(in pack: PackID) -> [Puzzle] {
        all.filter { $0.packId == pack }
    }

    /// Lookup by id.
    static func puzzle(id: String) -> Puzzle? {
        all.first { $0.id == id }
    }

    // MARK: - Construction

    private static func build() -> [Puzzle] {
        var out: [Puzzle] = []
        out += pack(.starter,    count: 12, colorCounts: [3, 3, 4, 4, 4, 5, 3, 4, 5, 4, 5, 3])
        out += pack(.classic,    count: 12, colorCounts: [4, 4, 5, 5, 5, 6, 4, 5, 6, 5, 6, 4])
        out += pack(.tricky,     count: 10, colorCounts: [5, 5, 6, 6, 7, 5, 6, 7, 6, 7])
        out += pack(.master,     count: 7,  colorCounts: [6, 6, 7, 7, 8, 7, 8])
        out += pack(.mindbender, count: 4,  colorCounts: [7, 8, 8, 9])
        return out
    }

    /// Build `count` puzzles for a pack, each with the requested number of colors.
    private static func pack(_ packId: PackID, count: Int, colorCounts: [Int]) -> [Puzzle] {
        let size = packId.size
        var puzzles: [Puzzle] = []
        for i in 0..<count {
            let colors = colorCounts[safe: i] ?? min(4, PipeColor.allCases.count)
            let strategy = WeaveStrategy.allCases[safe: (i + packId.size) % WeaveStrategy.allCases.count] ?? .boustrophedon
            let snake = makeSnake(size: size, strategy: strategy, variant: i)
            let pairs = cut(snake: snake, into: colors, variant: i)
            let id = "\(packId.rawValue)-\(i + 1)"
            let name = "\(packId.title) \(i + 1)"
            puzzles.append(Puzzle(id: id, packId: packId, size: size, name: name, pairs: pairs))
        }
        return puzzles
    }

    // MARK: - Snake generation (Hamiltonian paths)

    private enum WeaveStrategy: CaseIterable {
        case boustrophedon   // row-by-row serpentine
        case columnSerpentine // column-by-column serpentine
        case spiral          // inward spiral
        case combWeave       // vertical comb that returns along the top row
    }

    /// Produce a Hamiltonian path visiting every cell exactly once.
    private static func makeSnake(size: Int, strategy: WeaveStrategy, variant: Int) -> [Cell] {
        switch strategy {
        case .boustrophedon:   return boustrophedon(size: size, flip: variant % 2 == 0)
        case .columnSerpentine: return columnSerpentine(size: size, flip: variant % 2 == 0)
        case .spiral:          return spiral(size: size)
        case .combWeave:       return combWeave(size: size)
        }
    }

    /// Row-by-row serpentine: left-right on even rows, right-left on odd rows.
    private static func boustrophedon(size: Int, flip: Bool) -> [Cell] {
        var path: [Cell] = []
        for r in 0..<size {
            let leftToRight = (r % 2 == 0) != flip
            if leftToRight {
                for c in 0..<size { path.append(Cell(r, c)) }
            } else {
                for c in stride(from: size - 1, through: 0, by: -1) { path.append(Cell(r, c)) }
            }
        }
        return path
    }

    /// Column-by-column serpentine.
    private static func columnSerpentine(size: Int, flip: Bool) -> [Cell] {
        var path: [Cell] = []
        for c in 0..<size {
            let topToBottom = (c % 2 == 0) != flip
            if topToBottom {
                for r in 0..<size { path.append(Cell(r, c)) }
            } else {
                for r in stride(from: size - 1, through: 0, by: -1) { path.append(Cell(r, c)) }
            }
        }
        return path
    }

    /// Inward clockwise spiral. Hamiltonian but NOT a single open snake at the very
    /// end is fine — a spiral over a square visits each cell once and each step is
    /// orthogonal, so it is a valid Hamiltonian path.
    private static func spiral(size: Int) -> [Cell] {
        var path: [Cell] = []
        var top = 0, bottom = size - 1, left = 0, right = size - 1
        while top <= bottom && left <= right {
            for c in left...right { path.append(Cell(top, c)) }
            top += 1
            if top > bottom { break }
            for r in top...bottom { path.append(Cell(r, right)) }
            right -= 1
            if left > right { break }
            for c in stride(from: right, through: left, by: -1) { path.append(Cell(bottom, c)) }
            bottom -= 1
            if top > bottom { break }
            for r in stride(from: bottom, through: top, by: -1) { path.append(Cell(r, left)) }
            left += 1
        }
        return path
    }

    /// A "comb": go down each column fully, hop one cell right along the bottom or top.
    /// Implemented as a vertical serpentine identical in spirit to columnSerpentine but
    /// always starting downward — kept distinct so cut points differ.
    private static func combWeave(size: Int) -> [Cell] {
        columnSerpentine(size: size, flip: false)
    }

    // MARK: - Cutting the snake into colored segments

    /// Cut the snake into `colors` contiguous, roughly even segments. Each segment's
    /// two ends become a color's endpoints; the whole segment is its solution path.
    private static func cut(snake: [Cell], into colors: Int, variant: Int) -> [ColorPair] {
        let n = snake.count
        let palette = PipeColor.allCases
        let colorCount = max(1, min(colors, palette.count, n))

        // Choose cut boundaries. Start from an even split, then nudge boundaries by a
        // deterministic offset so different puzzles of the same size feel different.
        var boundaries: [Int] = []
        for k in 1..<colorCount {
            let base = (n * k) / colorCount
            let nudge = ((variant + k) % 3) - 1   // -1, 0, or +1
            let b = min(max(base + nudge, k), n - (colorCount - k))
            boundaries.append(b)
        }
        // Ensure strictly increasing boundaries.
        var cleaned: [Int] = []
        var prev = 0
        for b in boundaries.sorted() {
            let v = max(b, prev + 1)
            cleaned.append(v)
            prev = v
        }

        var pairs: [ColorPair] = []
        var start = 0
        for k in 0..<colorCount {
            let end = (k < cleaned.count) ? cleaned[safe: k] ?? n : n
            let safeEnd = min(max(end, start + 1), n)
            let segment = Array(snake[start..<safeEnd])
            if let color = palette[safe: k], !segment.isEmpty {
                pairs.append(ColorPair(color: color, solution: segment))
            }
            start = safeEnd
            if start >= n { break }
        }
        // If rounding left cells uncovered (shouldn't happen, but guard), append them
        // to the last segment so coverage is always 100%.
        if start < n, let last = pairs.last {
            let tail = Array(snake[start..<n])
            let merged = last.solution + tail
            pairs[pairs.count - 1] = ColorPair(color: last.color, solution: merged)
        }
        return pairs
    }
}
