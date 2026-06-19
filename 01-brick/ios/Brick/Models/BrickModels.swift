import Foundation
import SpriteKit

enum BrickColor: Int, CaseIterable {
    case red = 1, orange, yellow, green, blue, purple

    var skColor: SKColor {
        switch self {
        case .red:    return SKColor(red: 0.95, green: 0.22, blue: 0.18, alpha: 1)
        case .orange: return SKColor(red: 1.00, green: 0.55, blue: 0.10, alpha: 1)
        case .yellow: return SKColor(red: 1.00, green: 0.85, blue: 0.10, alpha: 1)
        case .green:  return SKColor(red: 0.20, green: 0.80, blue: 0.35, alpha: 1)
        case .blue:   return SKColor(red: 0.18, green: 0.50, blue: 0.95, alpha: 1)
        case .purple: return SKColor(red: 0.65, green: 0.25, blue: 0.90, alpha: 1)
        }
    }

    var points: Int { rawValue * 10 }
}

enum PowerUpKind: CaseIterable {
    case widePaddle, multiBall, laserPaddle, slowBall

    var symbol: String {
        switch self {
        case .widePaddle: return "W"
        case .multiBall:  return "M"
        case .laserPaddle: return "L"
        case .slowBall:   return "S"
        }
    }

    var color: SKColor {
        switch self {
        case .widePaddle:  return .cyan
        case .multiBall:   return .yellow
        case .laserPaddle: return .red
        case .slowBall:    return .green
        }
    }
}

struct BrickLayout {
    let rows: Int
    let cols: Int
    let grid: [[Int]]

    static let levels: [BrickLayout] = [
        BrickLayout(rows: 4, cols: 8, grid: [
            [1,1,1,1,1,1,1,1],
            [2,2,2,2,2,2,2,2],
            [3,3,3,3,3,3,3,3],
            [4,4,4,4,4,4,4,4]
        ]),
        BrickLayout(rows: 5, cols: 8, grid: [
            [0,1,0,2,2,0,1,0],
            [1,2,1,3,3,1,2,1],
            [2,3,2,4,4,2,3,2],
            [1,2,1,3,3,1,2,1],
            [0,1,0,2,2,0,1,0]
        ]),
        BrickLayout(rows: 6, cols: 8, grid: [
            [2,2,2,2,2,2,2,2],
            [2,3,3,3,3,3,3,2],
            [2,3,4,4,4,4,3,2],
            [2,3,4,5,5,4,3,2],
            [2,3,3,3,3,3,3,2],
            [2,2,2,2,2,2,2,2]
        ]),
        BrickLayout(rows: 6, cols: 9, grid: [
            [1,0,1,0,1,0,1,0,1],
            [0,2,0,2,0,2,0,2,0],
            [3,0,3,0,3,0,3,0,3],
            [0,4,0,4,0,4,0,4,0],
            [5,0,5,0,5,0,5,0,5],
            [0,6,0,6,0,6,0,6,0]
        ]),
        BrickLayout(rows: 7, cols: 9, grid: [
            [0,0,0,3,3,3,0,0,0],
            [0,0,3,4,4,4,3,0,0],
            [0,3,4,5,5,5,4,3,0],
            [3,4,5,6,6,6,5,4,3],
            [0,3,4,5,5,5,4,3,0],
            [0,0,3,4,4,4,3,0,0],
            [0,0,0,3,3,3,0,0,0]
        ]),
        BrickLayout(rows: 8, cols: 10, grid: [
            [3,3,3,3,3,3,3,3,3,3],
            [3,4,4,4,4,4,4,4,4,3],
            [3,4,5,5,5,5,5,5,4,3],
            [3,4,5,6,6,6,6,5,4,3],
            [3,4,5,6,6,6,6,5,4,3],
            [3,4,5,5,5,5,5,5,4,3],
            [3,4,4,4,4,4,4,4,4,3],
            [3,3,3,3,3,3,3,3,3,3]
        ])
    ]
}

struct LevelRecord: Identifiable {
    let id = UUID()
    let level: Int
    var highScore: Int
    var completed: Bool
}
