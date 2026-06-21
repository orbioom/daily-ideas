import Foundation
import SwiftUI

// MARK: - Direction

enum Direction {
    case up, down, left, right

    var delta: (row: Int, col: Int) {
        switch self {
        case .up:    return (-1,  0)
        case .down:  return ( 1,  0)
        case .left:  return ( 0, -1)
        case .right: return ( 0,  1)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .up:    return "Move up"
        case .down:  return "Move down"
        case .left:  return "Move left"
        case .right: return "Move right"
        }
    }
}

// MARK: - History Entry

private struct HistoryEntry {
    let grid: [[SokobanCell]]
    let playerPos: (row: Int, col: Int)
    let moves: Int
    let pushes: Int
}

// MARK: - Game Engine

@Observable
final class SokobanGame {
    // MARK: State
    var grid: [[SokobanCell]]
    var playerPos: (row: Int, col: Int)
    var moves: Int = 0
    var pushes: Int = 0
    var isSolvedAnimating: Bool = false

    // MARK: Level reference
    let level: SokobanLevel

    // MARK: Private
    private var history: [HistoryEntry] = []

    // MARK: Init
    init(level: SokobanLevel) {
        self.level = level
        self.grid = level.grid
        self.playerPos = level.playerStart ?? (0, 0)
    }

    // MARK: Computed

    /// True when every target cell has a box on it (no plain .box remains)
    var isSolved: Bool {
        // Count boxes not on target
        let unsettled = grid.flatMap { $0 }.filter { $0 == .box }.count
        return unsettled == 0 && level.boxCount > 0
    }

    var canUndo: Bool { !history.isEmpty }

    // MARK: - Move

    @discardableResult
    func move(_ direction: Direction) -> Bool {
        let d = direction.delta
        let newRow = playerPos.row + d.row
        let newCol = playerPos.col + d.col

        // Bounds check
        guard newRow >= 0, newRow < grid.count,
              newCol >= 0, newCol < grid[0].count else { return false }

        let targetCell = grid[newRow][newCol]

        // Can't walk into walls
        guard targetCell != .wall else { return false }

        // Save current state for undo
        let snapshot = HistoryEntry(grid: grid, playerPos: playerPos, moves: moves, pushes: pushes)

        if targetCell == .box || targetCell == .boxOnTarget {
            // Attempt to push box
            let boxRow = newRow + d.row
            let boxCol = newCol + d.col

            guard boxRow >= 0, boxRow < grid.count,
                  boxCol >= 0, boxCol < grid[0].count else { return false }

            let beyondCell = grid[boxRow][boxCol]
            guard beyondCell == .floor || beyondCell == .target else { return false }

            // Commit history now that we know move is valid
            history.append(snapshot)

            // Place box in new position
            grid[boxRow][boxCol] = (beyondCell == .target) ? .boxOnTarget : .box

            // Clear box's old position — restore underlying cell
            // If box was on target, reveal target; otherwise floor
            grid[newRow][newCol] = (targetCell == .boxOnTarget) ? .target : .floor

            pushes += 1
        } else {
            // Simple walk — must be floor or target
            history.append(snapshot)
        }

        // Move player
        // Restore old player cell
        let oldCell = grid[playerPos.row][playerPos.col]
        grid[playerPos.row][playerPos.col] = (oldCell == .playerOnTarget) ? .target : .floor

        // Place player in new position (cell is now floor or target after potential box move)
        let landCell = grid[newRow][newCol]
        grid[newRow][newCol] = (landCell == .target) ? .playerOnTarget : .player

        playerPos = (newRow, newCol)
        moves += 1
        return true
    }

    // MARK: - Undo

    func undo() {
        guard let entry = history.popLast() else { return }
        grid = entry.grid
        playerPos = entry.playerPos
        moves = entry.moves
        pushes = entry.pushes
    }

    // MARK: - Reset

    func reset() {
        grid = level.grid
        playerPos = level.playerStart ?? (0, 0)
        moves = 0
        pushes = 0
        history.removeAll()
    }

    // MARK: - Stars

    func stars(parMoves: Int) -> Int {
        guard isSolved else { return 0 }
        if moves <= parMoves { return 3 }
        if moves <= Int(Double(parMoves) * 1.5) { return 2 }
        return 1
    }
}
