import Foundation

struct GameMap: Identifiable {
    let id: Int
    let name: String
    let difficulty: Int  // 1-3 stars
    let path: [CGPoint]  // waypoints in 320x480 game-space coordinates
    var cells: [[GameCell]]  // cells[row][col], 24 rows x 16 cols, 20x20 units each

    static let all: [GameMap] = [map1, map2, map3, map4, map5]

    // MARK: - Cell Grid Builder

    static func buildCells(path: [CGPoint]) -> [[GameCell]] {
        let rows = 24
        let cols = 16
        let cellSize: Double = 20.0
        var grid: [[GameCell]] = []

        for row in 0..<rows {
            var rowCells: [GameCell] = []
            for col in 0..<cols {
                let cellCenter = CGPoint(
                    x: Double(col) * cellSize + cellSize / 2,
                    y: Double(row) * cellSize + cellSize / 2
                )
                let isOnPath = isNearPath(point: cellCenter, path: path, threshold: 12.0)
                rowCells.append(GameCell(col: col, row: row, isPath: isOnPath, isBuildable: !isOnPath))
            }
            grid.append(rowCells)
        }
        return grid
    }

    static func isNearPath(point: CGPoint, path: [CGPoint], threshold: Double) -> Bool {
        guard path.count >= 2 else { return false }
        for i in 0..<(path.count - 1) {
            let dist = distanceFromPointToSegment(point: point, segA: path[i], segB: path[i + 1])
            if dist <= threshold { return true }
        }
        return false
    }

    static func distanceFromPointToSegment(point: CGPoint, segA: CGPoint, segB: CGPoint) -> Double {
        let dx = segB.x - segA.x
        let dy = segB.y - segA.y
        let lengthSq = dx * dx + dy * dy
        if lengthSq == 0 {
            let ex = point.x - segA.x
            let ey = point.y - segA.y
            return sqrt(ex * ex + ey * ey)
        }
        var t = ((point.x - segA.x) * dx + (point.y - segA.y) * dy) / lengthSq
        t = max(0, min(1, t))
        let projX = segA.x + t * dx
        let projY = segA.y + t * dy
        let ex = point.x - projX
        let ey = point.y - projY
        return sqrt(ex * ex + ey * ey)
    }

    // MARK: - Map 1: Stone Gate — simple S-curve

    static let map1: GameMap = {
        let path: [CGPoint] = [
            CGPoint(x: 30, y: 10),
            CGPoint(x: 30, y: 120),
            CGPoint(x: 160, y: 160),
            CGPoint(x: 290, y: 200),
            CGPoint(x: 290, y: 320),
            CGPoint(x: 160, y: 360),
            CGPoint(x: 30, y: 400),
            CGPoint(x: 30, y: 470)
        ]
        let cells = buildCells(path: path)
        return GameMap(id: 1, name: "Stone Gate", difficulty: 1, path: path, cells: cells)
    }()

    // MARK: - Map 2: River Crossing — path curves back

    static let map2: GameMap = {
        let path: [CGPoint] = [
            CGPoint(x: 160, y: 10),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 60, y: 140),
            CGPoint(x: 60, y: 240),
            CGPoint(x: 260, y: 280),
            CGPoint(x: 260, y: 380),
            CGPoint(x: 160, y: 420),
            CGPoint(x: 160, y: 470)
        ]
        let cells = buildCells(path: path)
        return GameMap(id: 2, name: "River Crossing", difficulty: 1, path: path, cells: cells)
    }()

    // MARK: - Map 3: Forest Trail — multiple turns

    static let map3: GameMap = {
        let path: [CGPoint] = [
            CGPoint(x: 300, y: 30),
            CGPoint(x: 200, y: 30),
            CGPoint(x: 200, y: 130),
            CGPoint(x: 100, y: 130),
            CGPoint(x: 100, y: 230),
            CGPoint(x: 220, y: 230),
            CGPoint(x: 220, y: 330),
            CGPoint(x: 80, y: 330),
            CGPoint(x: 80, y: 450),
            CGPoint(x: 160, y: 470)
        ]
        let cells = buildCells(path: path)
        return GameMap(id: 3, name: "Forest Trail", difficulty: 2, path: path, cells: cells)
    }()

    // MARK: - Map 4: Mountain Pass — long straight sections (Pro)

    static let map4: GameMap = {
        let path: [CGPoint] = [
            CGPoint(x: 20, y: 20),
            CGPoint(x: 300, y: 20),
            CGPoint(x: 300, y: 120),
            CGPoint(x: 20, y: 120),
            CGPoint(x: 20, y: 240),
            CGPoint(x: 300, y: 240),
            CGPoint(x: 300, y: 360),
            CGPoint(x: 20, y: 360),
            CGPoint(x: 20, y: 460),
            CGPoint(x: 160, y: 470)
        ]
        let cells = buildCells(path: path)
        return GameMap(id: 4, name: "Mountain Pass", difficulty: 2, path: path, cells: cells)
    }()

    // MARK: - Map 5: Dragon's Lair — complex maze-like path (Pro)

    static let map5: GameMap = {
        let path: [CGPoint] = [
            CGPoint(x: 160, y: 10),
            CGPoint(x: 280, y: 60),
            CGPoint(x: 280, y: 160),
            CGPoint(x: 160, y: 200),
            CGPoint(x: 40, y: 160),
            CGPoint(x: 40, y: 280),
            CGPoint(x: 160, y: 320),
            CGPoint(x: 280, y: 280),
            CGPoint(x: 280, y: 400),
            CGPoint(x: 160, y: 440),
            CGPoint(x: 80, y: 470)
        ]
        let cells = buildCells(path: path)
        return GameMap(id: 5, name: "Dragon's Lair", difficulty: 3, path: path, cells: cells)
    }()
}
