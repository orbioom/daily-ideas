import Foundation

struct WinPattern: Identifiable {
    let id = UUID()
    let name: String
    let cells: [(Int, Int)]
}

struct WinDetector {
    static func checkWins(grid: [[String]], marked: [[Bool]], enabledPatterns: [String]) -> [WinPattern] {
        var wins: [WinPattern] = []

        if enabledPatterns.contains("row") {
            for row in 0..<5 {
                let cells = (0..<5).map { (row, $0) }
                if cells.allSatisfy({ marked[$0.0][$0.1] }) {
                    wins.append(WinPattern(name: "row", cells: cells))
                }
            }
        }

        if enabledPatterns.contains("column") {
            for col in 0..<5 {
                let cells = (0..<5).map { ($0, col) }
                if cells.allSatisfy({ marked[$0.0][$0.1] }) {
                    wins.append(WinPattern(name: "column", cells: cells))
                }
            }
        }

        if enabledPatterns.contains("diagonal") {
            let diag1 = [(0, 0), (1, 1), (2, 2), (3, 3), (4, 4)]
            if diag1.allSatisfy({ marked[$0.0][$0.1] }) {
                wins.append(WinPattern(name: "diagonal", cells: diag1))
            }
            let diag2 = [(0, 4), (1, 3), (2, 2), (3, 1), (4, 0)]
            if diag2.allSatisfy({ marked[$0.0][$0.1] }) {
                wins.append(WinPattern(name: "diagonal", cells: diag2))
            }
        }

        if enabledPatterns.contains("corners") {
            let corners = [(0, 0), (0, 4), (4, 0), (4, 4)]
            if corners.allSatisfy({ marked[$0.0][$0.1] }) {
                wins.append(WinPattern(name: "corners", cells: corners))
            }
        }

        if enabledPatterns.contains("blackout") {
            let all = (0..<5).flatMap { r in (0..<5).map { c in (r, c) } }
            if all.allSatisfy({ marked[$0.0][$0.1] }) {
                wins.append(WinPattern(name: "blackout", cells: all))
            }
        }

        return wins
    }

    static func isWinningCell(row: Int, col: Int, patterns: [WinPattern]) -> Bool {
        patterns.contains { pattern in
            pattern.cells.contains { $0.0 == row && $0.1 == col }
        }
    }
}
