import Foundation
import Observation

// MARK: - Types

enum CellState {
    case empty, ship, hit, miss
}

struct SalvoShip: Identifiable {
    let id = UUID()
    var name: String
    var size: Int
    var cells: [(Int, Int)] = []
    var hits: Set<Int> = []  // indices into cells
    var isSunk: Bool { hits.count == size }
}

// MARK: - Engine

@Observable
@MainActor
final class SalvoEngine {
    // 10×10 grid, row-major index = row*10 + col
    private(set) var playerGrid: [CellState] = Array(repeating: .empty, count: 100)
    private(set) var aiGrid: [CellState] = Array(repeating: .empty, count: 100)
    private(set) var playerShips: [SalvoShip] = []
    private(set) var aiShips: [SalvoShip] = []
    private(set) var phase: GamePhase = .setup
    private(set) var isAITurn: Bool = false
    private(set) var aiMessage: String = ""
    private(set) var shotsPlayer: Int = 0
    private(set) var shotsAI: Int = 0
    var difficulty: String = "Normal"

    enum GamePhase { case setup, playing, gameOver(String) }

    private let shipDefs: [(String, Int)] = [
        ("Carrier", 5), ("Battleship", 4), ("Cruiser", 3), ("Submarine", 3), ("Destroyer", 2)
    ]

    // AI hunt/target state
    private var aiHits: [(Int, Int)] = []
    private var aiTargetQueue: [(Int, Int)] = []

    func startGame(difficulty: String) {
        self.difficulty = difficulty
        playerGrid = Array(repeating: .empty, count: 100)
        aiGrid = Array(repeating: .empty, count: 100)
        playerShips = []
        aiShips = []
        shotsPlayer = 0
        shotsAI = 0
        aiHits = []
        aiTargetQueue = []
        aiMessage = ""

        playerShips = placeShipsRandomly(on: &playerGrid)
        aiShips = placeShipsRandomly(on: &aiGrid)
        phase = .playing
        isAITurn = false
    }

    func playerShoot(row: Int, col: Int) {
        guard case .playing = phase, !isAITurn else { return }
        let idx = row * 10 + col
        guard aiGrid[idx] == .empty || aiGrid[idx] == .ship else { return }

        shotsPlayer += 1
        let isHit = aiGrid[idx] == .ship
        aiGrid[idx] = isHit ? .hit : .miss

        if isHit {
            markShipHit(row: row, col: col, ships: &aiShips)
        }

        if aiShips.allSatisfy(\.isSunk) {
            phase = .gameOver("win")
            return
        }
        isAITurn = true
        Task { await runAIShot() }
    }

    private func runAIShot() async {
        let delay: UInt64
        switch difficulty {
        case "Easy": delay = 1_200_000_000
        case "Hard": delay = 400_000_000
        default: delay = 700_000_000
        }
        try? await Task.sleep(nanoseconds: delay)
        await MainActor.run { executeAIShot() }
    }

    private func executeAIShot() {
        let (row, col) = pickAICell()
        let idx = row * 10 + col
        shotsAI += 1
        let isHit = playerGrid[idx] == .ship
        playerGrid[idx] = isHit ? .hit : .miss

        if isHit {
            aiHits.append((row, col))
            markShipHit(row: row, col: col, ships: &playerShips)
            let sunk = playerShips.first(where: { $0.isSunk && $0.cells.contains(where: { $0 == (row, col) }) })
            if sunk != nil {
                aiTargetQueue = []
                aiHits = []
                aiMessage = "AI sunk your \(sunk!.name)!"
            } else {
                enqueueAdjacentCells(row: row, col: col)
                aiMessage = "AI hit your ship!"
            }
        } else {
            aiMessage = difficulty == "Hard" ? "AI missed." : "AI fired..."
        }

        if playerShips.allSatisfy(\.isSunk) {
            phase = .gameOver("loss")
            return
        }
        isAITurn = false
    }

    private func pickAICell() -> (Int, Int) {
        while !aiTargetQueue.isEmpty {
            let candidate = aiTargetQueue.removeFirst()
            let idx = candidate.0 * 10 + candidate.1
            if playerGrid[idx] == .empty || playerGrid[idx] == .ship {
                return candidate
            }
        }
        if difficulty == "Hard" {
            return checkerboardShot()
        }
        return randomShot()
    }

    private func randomShot() -> (Int, Int) {
        var r, c: Int
        repeat { r = Int.random(in: 0..<10); c = Int.random(in: 0..<10) }
        while !(playerGrid[r*10+c] == .empty || playerGrid[r*10+c] == .ship)
        return (r, c)
    }

    private func checkerboardShot() -> (Int, Int) {
        var candidates: [(Int, Int)] = []
        for r in 0..<10 {
            for c in 0..<10 {
                let idx = r * 10 + c
                if (r + c) % 2 == 0, playerGrid[idx] == .empty || playerGrid[idx] == .ship {
                    candidates.append((r, c))
                }
            }
        }
        if candidates.isEmpty { return randomShot() }
        return candidates.randomElement()!
    }

    private func enqueueAdjacentCells(row: Int, col: Int) {
        let dirs = [(-1,0),(1,0),(0,-1),(0,1)]
        for (dr, dc) in dirs {
            let nr = row + dr, nc = col + dc
            guard nr >= 0, nr < 10, nc >= 0, nc < 10 else { continue }
            let idx = nr * 10 + nc
            guard playerGrid[idx] == .empty || playerGrid[idx] == .ship else { continue }
            if !aiTargetQueue.contains(where: { $0 == (nr, nc) }) {
                aiTargetQueue.append((nr, nc))
            }
        }
    }

    private func markShipHit(row: Int, col: Int, ships: inout [SalvoShip]) {
        for i in ships.indices {
            if let ci = ships[i].cells.firstIndex(where: { $0 == (row, col) }) {
                ships[i].hits.insert(ci)
                return
            }
        }
    }

    // MARK: - Ship Placement

    private func placeShipsRandomly(on grid: inout [CellState]) -> [SalvoShip] {
        var ships: [SalvoShip] = []
        for (name, size) in shipDefs {
            var placed = false
            while !placed {
                let horiz = Bool.random()
                let maxR = horiz ? 10 : (10 - size)
                let maxC = horiz ? (10 - size) : 10
                let r = Int.random(in: 0..<maxR)
                let c = Int.random(in: 0..<maxC)
                var cells: [(Int, Int)] = []
                for i in 0..<size {
                    cells.append(horiz ? (r, c + i) : (r + i, c))
                }
                let occupied = cells.contains(where: { grid[$0.0 * 10 + $0.1] != .empty })
                if !occupied {
                    for cell in cells { grid[cell.0 * 10 + cell.1] = .ship }
                    var ship = SalvoShip(name: name, size: size)
                    ship.cells = cells
                    ships.append(ship)
                    placed = true
                }
            }
        }
        return ships
    }
}
