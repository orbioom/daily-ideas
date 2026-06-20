import Foundation
import Observation

enum DropPlayer: String, CaseIterable {
    case human = "human"
    case cpu = "cpu"

    var other: DropPlayer { self == .human ? .cpu : .human }
}

enum DropCell: Equatable {
    case empty, human, cpu
}

enum DropPhase {
    case playing, won(DropPlayer), draw
}

@Observable
final class DropGame {
    static let cols = 7
    static let rows = 6

    private(set) var grid: [[DropCell]]
    private(set) var currentPlayer: DropPlayer
    private(set) var phase: DropPhase
    private(set) var winningCells: Set<[Int]>
    private(set) var moveCount: Int
    private(set) var lastDropCol: Int?
    var difficulty: Int  // 1=easy(depth3), 2=medium(depth5), 3=hard(depth7)

    init(difficulty: Int = 2) {
        self.difficulty = difficulty
        self.grid = Array(repeating: Array(repeating: .empty, count: Self.cols), count: Self.rows)
        self.currentPlayer = .human
        self.phase = .playing
        self.winningCells = []
        self.moveCount = 0
        self.lastDropCol = nil
    }

    func reset() {
        grid = Array(repeating: Array(repeating: .empty, count: Self.cols), count: Self.rows)
        currentPlayer = .human
        phase = .playing
        winningCells = []
        moveCount = 0
        lastDropCol = nil
    }

    func resetForCPUFirst() {
        reset()
        currentPlayer = .cpu
    }

    /// Returns the row where the disc lands, or nil if column is full
    func availableRow(col: Int) -> Int? {
        guard col >= 0 && col < Self.cols else { return nil }
        for row in stride(from: Self.rows - 1, through: 0, by: -1) {
            if grid[row][col] == .empty { return row }
        }
        return nil
    }

    @discardableResult
    func drop(col: Int, player: DropPlayer) -> Bool {
        guard case .playing = phase else { return false }
        guard let row = availableRow(col: col) else { return false }

        grid[row][col] = player == .human ? .human : .cpu
        moveCount += 1
        lastDropCol = col

        if let win = findWin(row: row, col: col, player: player) {
            winningCells = Set(win.map { [$0.0, $0.1] })
            phase = .won(player)
        } else if moveCount == Self.rows * Self.cols {
            phase = .draw
        } else {
            currentPlayer = player.other
        }
        return true
    }

    func dropHuman(col: Int) {
        guard currentPlayer == .human else { return }
        drop(col: col, player: .human)
    }

    func dropCPU() {
        guard currentPlayer == .cpu else { return }
        let depth = [1: 3, 2: 5, 3: 7][difficulty] ?? 5
        let col = DropAI.bestMove(grid: grid, depth: depth)
        drop(col: col, player: .cpu)
    }

    private func findWin(row: Int, col: Int, player: DropPlayer) -> [(Int, Int)]? {
        let cell: DropCell = player == .human ? .human : .cpu
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        for (dr, dc) in directions {
            var line = [(row, col)]
            for sign in [1, -1] {
                var r = row + sign * dr
                var c = col + sign * dc
                while r >= 0 && r < Self.rows && c >= 0 && c < Self.cols && grid[r][c] == cell {
                    line.append((r, c))
                    r += sign * dr
                    c += sign * dc
                }
            }
            if line.count >= 4 { return line }
        }
        return nil
    }

    var availableCols: [Int] {
        (0..<Self.cols).filter { availableRow(col: $0) != nil }
    }

    var isOver: Bool {
        switch phase {
        case .playing: return false
        default: return true
        }
    }
}
