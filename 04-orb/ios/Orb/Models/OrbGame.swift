import Foundation
import SwiftUI
import Observation

enum OrbPhase: Equatable {
    case playing, levelComplete, gameOver, victory
}

@Observable
final class OrbGame {
    private(set) var grid = BubbleGrid()
    private(set) var phase: OrbPhase = .playing
    private(set) var currentBubble: BubbleColor = .red
    private(set) var nextBubble: BubbleColor = .blue
    private(set) var shotsUsed: Int = 0
    private(set) var score: Int = 0
    private(set) var currentLevel: Int = 1
    private(set) var popCount: Int = 0
    private(set) var lastPopCount: Int = 0
    private(set) var aimAngle: Double = -.pi / 2
    private(set) var poppedPositions: Set<GridPos> = []

    private var availableColors: Set<BubbleColor> = []

    func loadLevel(_ levelNum: Int) {
        guard let level = LevelDefinition.all.first(where: { $0.number == levelNum }) else { return }
        grid = BubbleGrid()
        grid.loadLevel(level)
        phase = .playing
        shotsUsed = 0
        popCount = 0
        lastPopCount = 0
        currentLevel = levelNum
        poppedPositions = []
        availableColors = grid.colorsInGrid
        randomizeBubbles()
    }

    private func randomizeBubbles() {
        let colors = Array(availableColors.isEmpty ? Set(BubbleColor.allCases) : availableColors)
        currentBubble = colors.randomElement() ?? .red
        nextBubble = colors.randomElement() ?? .blue
    }

    func setAimAngle(_ angle: Double) {
        let clamped = max(-.pi * 0.92, min(-.pi * 0.08, angle))
        aimAngle = clamped
    }

    // Compute aim trajectory points for rendering (with wall bounces)
    func aimTrajectory(from start: CGPoint, in rect: CGRect, steps: Int = 200) -> [CGPoint] {
        var points: [CGPoint] = [start]
        var x = Double(start.x)
        var y = Double(start.y)
        let speed = 8.0
        var velX = cos(aimAngle) * speed
        var velY = sin(aimAngle) * speed

        for _ in 0..<steps {
            x += velX
            y += velY

            if x < Double(rect.minX) {
                x = Double(rect.minX)
                velX = abs(velX)
            }
            if x > Double(rect.maxX) {
                x = Double(rect.maxX)
                velX = -abs(velX)
            }

            if y <= Double(rect.minY) {
                points.append(CGPoint(x: x, y: rect.minY))
                break
            }

            points.append(CGPoint(x: x, y: y))

            // Check bubble collision
            let colW = Double(rect.width) / Double(BubbleGrid.cols)
            let rowH = colW * 0.45 * 1.8
            let hitRadius = colW * 0.45
            var hit = false
            outerLoop: for r in 0..<BubbleGrid.rows {
                for c in 0..<BubbleGrid.cols {
                    guard grid.cells[r][c] != nil else { continue }
                    let offset = r % 2 == 1 ? colW * 0.5 : 0
                    let bx = Double(rect.minX) + offset + Double(c) * colW + colW / 2
                    let by = Double(rect.minY) + Double(r) * rowH + rowH / 2
                    if sqrt(pow(x - bx, 2) + pow(y - by, 2)) < hitRadius * 1.8 {
                        hit = true
                        break outerLoop
                    }
                }
            }
            if hit { break }
        }
        return points
    }

    func shoot(gridRect: CGRect) {
        guard phase == .playing else { return }

        let startX = gridRect.midX
        let startY = gridRect.maxY + 60.0

        var x = Double(startX)
        var y = Double(startY)
        let speed = 14.0
        var velX = cos(aimAngle) * speed
        var velY = sin(aimAngle) * speed

        var finalX = x
        var finalY = y
        let maxSteps = 2000

        for _ in 0..<maxSteps {
            x += velX
            y += velY

            if x < Double(gridRect.minX) {
                x = Double(gridRect.minX)
                velX = abs(velX)
            }
            if x > Double(gridRect.maxX) {
                x = Double(gridRect.maxX)
                velX = -abs(velX)
            }

            if y <= Double(gridRect.minY) {
                finalX = x
                finalY = Double(gridRect.minY)
                break
            }

            let colW = Double(gridRect.width) / Double(BubbleGrid.cols)
            let rowH = colW * 0.45 * 1.8
            let hitRadius = colW * 0.45

            var hitSomething = false
            outerLoop: for r in 0..<BubbleGrid.rows {
                for c in 0..<BubbleGrid.cols {
                    guard grid.cells[r][c] != nil else { continue }
                    let offset = r % 2 == 1 ? colW * 0.5 : 0
                    let bx = Double(gridRect.minX) + offset + Double(c) * colW + colW / 2
                    let by = Double(gridRect.minY) + Double(r) * rowH + rowH / 2
                    if sqrt(pow(x - bx, 2) + pow(y - by, 2)) < hitRadius * 1.8 {
                        finalX = x - velX
                        finalY = y - velY
                        hitSomething = true
                        break outerLoop
                    }
                }
            }
            if hitSomething { break }

            finalX = x
            finalY = y
        }

        let landing = CGPoint(x: finalX, y: finalY)
        if let pos = grid.place(bubble: Bubble(color: currentBubble), at: landing, gridRect: gridRect) {
            processMatch(at: pos)
        }

        shotsUsed += 1
        currentBubble = nextBubble
        availableColors = grid.colorsInGrid
        let colors = Array(availableColors.isEmpty ? Set(BubbleColor.allCases) : availableColors)
        nextBubble = colors.randomElement() ?? .red

        if grid.isEmpty {
            score += max(0, 500 - shotsUsed * 10)
            phase = .levelComplete
            return
        }

        for c in 0..<BubbleGrid.cols {
            if grid.cells[BubbleGrid.rows - 1][c] != nil {
                phase = .gameOver
                return
            }
        }
    }

    private func processMatch(at pos: GridPos) {
        let matched = grid.findMatch(at: pos)
        if matched.count >= 3 {
            grid.remove(positions: matched)
            lastPopCount = matched.count
            popCount += matched.count
            score += matched.count * 10
            poppedPositions = matched

            let disconnected = grid.findDisconnected()
            if !disconnected.isEmpty {
                grid.remove(positions: disconnected)
                score += disconnected.count * 15
                popCount += disconnected.count
                lastPopCount += disconnected.count
                poppedPositions = poppedPositions.union(disconnected)
            }
        } else {
            lastPopCount = 0
            poppedPositions = []
        }
    }

    func swapBubbles() {
        let temp = currentBubble
        currentBubble = nextBubble
        nextBubble = temp
    }

    func nextLevel() {
        let next = currentLevel + 1
        if next <= LevelDefinition.all.count {
            loadLevel(next)
        } else {
            phase = .victory
        }
    }

    func restartLevel() {
        loadLevel(currentLevel)
    }
}
