import Foundation
import SwiftUI

enum BubbleColor: Int, CaseIterable, Codable {
    case red = 1, blue = 2, green = 3, yellow = 4, purple = 5

    var uiColor: Color {
        switch self {
        case .red:    return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .blue:   return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .green:  return Color(red: 0.2, green: 0.8, blue: 0.3)
        case .yellow: return Color(red: 0.95, green: 0.75, blue: 0.1)
        case .purple: return Color(red: 0.7, green: 0.3, blue: 0.9)
        }
    }

    var colorBlindColor: Color {
        switch self {
        case .red:    return Color(red: 0.9, green: 0.6, blue: 0.0)
        case .blue:   return Color(red: 0.0, green: 0.45, blue: 0.7)
        case .green:  return Color(red: 0.0, green: 0.6, blue: 0.5)
        case .yellow: return Color(red: 0.94, green: 0.89, blue: 0.26)
        case .purple: return Color(red: 0.8, green: 0.47, blue: 0.65)
        }
    }

    func displayColor(colorBlind: Bool) -> Color {
        colorBlind ? colorBlindColor : uiColor
    }
}

struct GridPos: Hashable, Equatable {
    let row: Int
    let col: Int
}

struct Bubble {
    var color: BubbleColor
}

class BubbleGrid {
    static let rows = 8
    static let cols = 8

    var cells: [[Bubble?]]

    init() {
        cells = Array(repeating: Array(repeating: nil, count: Self.cols), count: Self.rows)
    }

    func loadLevel(_ level: LevelDefinition) {
        cells = Array(repeating: Array(repeating: nil, count: Self.cols), count: Self.rows)
        for r in 0..<min(Self.rows, level.grid.count) {
            for c in 0..<min(Self.cols, level.grid[r].count) {
                let val = level.grid[r][c]
                if val > 0, let color = BubbleColor(rawValue: val) {
                    cells[r][c] = Bubble(color: color)
                }
            }
        }
    }

    // Hex neighbors: odd rows offset right
    func neighbors(of pos: GridPos) -> [GridPos] {
        let r = pos.row, c = pos.col
        let isOdd = r % 2 == 1
        let dirs: [(Int, Int)] = isOdd
            ? [(-1, 0), (-1, 1), (0, -1), (0, 1), (1, 0), (1, 1)]
            : [(-1, -1), (-1, 0), (0, -1), (0, 1), (1, -1), (1, 0)]
        return dirs.compactMap { (dr, dc) in
            let nr = r + dr, nc = c + dc
            guard nr >= 0 && nr < Self.rows && nc >= 0 && nc < Self.cols else { return nil }
            return GridPos(row: nr, col: nc)
        }
    }

    func findMatch(at pos: GridPos) -> Set<GridPos> {
        guard let bubble = cells[pos.row][pos.col] else { return [] }
        let targetColor = bubble.color
        var visited = Set<GridPos>()
        var stack = [pos]
        while !stack.isEmpty {
            let current = stack.removeLast()
            guard !visited.contains(current) else { continue }
            guard let b = cells[current.row][current.col], b.color == targetColor else { continue }
            visited.insert(current)
            stack.append(contentsOf: neighbors(of: current).filter { !visited.contains($0) })
        }
        return visited
    }

    func findDisconnected() -> Set<GridPos> {
        var connected = Set<GridPos>()
        var stack: [GridPos] = []
        for c in 0..<Self.cols {
            if cells[0][c] != nil {
                let p = GridPos(row: 0, col: c)
                stack.append(p)
                connected.insert(p)
            }
        }
        while !stack.isEmpty {
            let cur = stack.removeLast()
            for n in neighbors(of: cur) {
                if !connected.contains(n) && cells[n.row][n.col] != nil {
                    connected.insert(n)
                    stack.append(n)
                }
            }
        }
        var disconnected = Set<GridPos>()
        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                if cells[r][c] != nil {
                    let p = GridPos(row: r, col: c)
                    if !connected.contains(p) { disconnected.insert(p) }
                }
            }
        }
        return disconnected
    }

    func remove(positions: Set<GridPos>) {
        for p in positions { cells[p.row][p.col] = nil }
    }

    var isEmpty: Bool {
        cells.allSatisfy { row in row.allSatisfy { $0 == nil } }
    }

    var colorsInGrid: Set<BubbleColor> {
        var colors = Set<BubbleColor>()
        for row in cells {
            for bubble in row {
                if let b = bubble { colors.insert(b.color) }
            }
        }
        return colors
    }

    func place(bubble: Bubble, at cgPoint: CGPoint, gridRect: CGRect) -> GridPos? {
        let colW = gridRect.width / CGFloat(Self.cols)
        let rowH = colW * 0.45 * 1.8

        var bestPos: GridPos? = nil
        var bestDist = CGFloat.infinity

        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                guard cells[r][c] == nil else { continue }
                let isAdjacent = r == 0 || neighbors(of: GridPos(row: r, col: c)).contains { cells[$0.row][$0.col] != nil }
                guard isAdjacent else { continue }

                let offset = r % 2 == 1 ? colW * 0.5 : 0
                let bx = gridRect.minX + offset + CGFloat(c) * colW + colW / 2
                let by = gridRect.minY + CGFloat(r) * rowH + rowH / 2
                let dist = sqrt(pow(cgPoint.x - bx, 2) + pow(cgPoint.y - by, 2))
                if dist < bestDist {
                    bestDist = dist
                    bestPos = GridPos(row: r, col: c)
                }
            }
        }

        let hitRadius = colW * 0.45
        if let pos = bestPos, bestDist < hitRadius * 2.0 {
            cells[pos.row][pos.col] = bubble
            return pos
        }
        return nil
    }

    func bubbleCenter(row: Int, col: Int, gridRect: CGRect) -> CGPoint {
        let colW = gridRect.width / CGFloat(Self.cols)
        let rowH = colW * 0.45 * 1.8
        let offset = row % 2 == 1 ? colW * 0.5 : 0
        return CGPoint(
            x: gridRect.minX + offset + CGFloat(col) * colW + colW / 2,
            y: gridRect.minY + CGFloat(row) * rowH + rowH / 2
        )
    }
}
