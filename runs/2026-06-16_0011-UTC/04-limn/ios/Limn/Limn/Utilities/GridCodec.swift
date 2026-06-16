import Foundation

/// Safely encodes / decodes a 2-D cell grid to a compact string for `SavedGame`.
/// Format: rows joined by ";", each row a run of digits "0"/"1"/"2" (CellState rawValue).
/// Decoding is total — malformed input yields `nil` so callers can fall back to a fresh
/// board rather than crashing.
enum GridCodec {
    static func encode(_ grid: [[CellState]]) -> String {
        grid.map { row in
            String(row.map { Character("\($0.rawValue)") })
        }
        .joined(separator: ";")
    }

    /// Decodes to a grid of the expected dimensions, or `nil` if the string doesn't match.
    static func decode(_ string: String, rows: Int, cols: Int) -> [[CellState]]? {
        guard rows > 0, cols > 0 else { return nil }
        let lines = string.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        guard lines.count == rows else { return nil }
        var grid: [[CellState]] = []
        grid.reserveCapacity(rows)
        for line in lines {
            guard line.count == cols else { return nil }
            var row: [CellState] = []
            row.reserveCapacity(cols)
            for ch in line {
                guard let v = ch.wholeNumberValue, let state = CellState(rawValue: v) else { return nil }
                row.append(state)
            }
            grid.append(row)
        }
        return grid
    }

    /// A fresh all-unknown grid of the given size.
    static func blank(rows: Int, cols: Int) -> [[CellState]] {
        let safeRows = max(rows, 1)
        let safeCols = max(cols, 1)
        return Array(repeating: Array(repeating: CellState.unknown, count: safeCols), count: safeRows)
    }
}
