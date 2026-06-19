import Foundation

enum Direction: CaseIterable {
    case up, down, left, right

    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var dx: Int {
        switch self { case .left: return -1; case .right: return 1; default: return 0 }
    }
    var dy: Int {
        switch self { case .up: return -1; case .down: return 1; default: return 0 }
    }
}

struct GridPoint: Hashable, Equatable {
    let x: Int
    let y: Int

    func moved(direction: Direction) -> GridPoint {
        GridPoint(x: x + direction.dx, y: y + direction.dy)
    }

    func wrapped(cols: Int, rows: Int) -> GridPoint {
        GridPoint(x: (x + cols) % cols, y: (y + rows) % rows)
    }
}

enum GameMode: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case wrap = "Wall Wrap"

    var id: String { rawValue }
    var description: String {
        self == .classic ? "Walls are deadly" : "Walls teleport the snake"
    }
}

enum GameState {
    case idle, playing, paused, dead
}

@Observable
class CrawlEngine {
    let cols: Int
    let rows: Int
    let mode: GameMode

    var snake: [GridPoint] = []
    var apple: GridPoint = GridPoint(x: 0, y: 0)
    var direction: Direction = .right
    var pendingDirection: Direction? = nil
    var gameState: GameState = .idle
    var score: Int = 0
    var applesEaten: Int = 0
    var highScore: Int = 0

    private var tickInterval: TimeInterval = 0.22
    private var timer: Timer?
    private var level = 1

    init(cols: Int = 20, rows: Int = 28, mode: GameMode = .classic) {
        self.cols = cols
        self.rows = rows
        self.mode = mode
        resetSnake()
    }

    func startGame() {
        resetSnake()
        gameState = .playing
        scheduleTimer()
    }

    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        timer?.invalidate()
    }

    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        scheduleTimer()
    }

    func handleSwipe(direction: Direction) {
        guard direction != self.direction.opposite else { return }
        pendingDirection = direction
    }

    private func resetSnake() {
        let startX = cols / 2
        let startY = rows / 2
        snake = [
            GridPoint(x: startX, y: startY),
            GridPoint(x: startX - 1, y: startY),
            GridPoint(x: startX - 2, y: startY)
        ]
        direction = .right
        pendingDirection = nil
        score = 0
        applesEaten = 0
        level = 1
        tickInterval = 0.22
        placeApple()
        gameState = .idle
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard gameState == .playing else { return }

        if let pending = pendingDirection {
            direction = pending
            pendingDirection = nil
        }

        guard let head = snake.first else { return }
        var newHead = head.moved(direction: direction)

        if mode == .wrap {
            newHead = newHead.wrapped(cols: cols, rows: rows)
        } else {
            if newHead.x < 0 || newHead.x >= cols || newHead.y < 0 || newHead.y >= rows {
                die()
                return
            }
        }

        if snake.dropFirst().contains(newHead) {
            die()
            return
        }

        snake.insert(newHead, at: 0)

        if newHead == apple {
            applesEaten += 1
            score += level * 10
            if applesEaten % 5 == 0 {
                level += 1
                tickInterval = max(0.08, tickInterval - 0.018)
                scheduleTimer()
            }
            placeApple()
        } else {
            snake.removeLast()
        }
    }

    private func die() {
        timer?.invalidate()
        gameState = .dead
        if score > highScore { highScore = score }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.error)
    }

    private func placeApple() {
        let snakeSet = Set(snake)
        var candidate = GridPoint(x: Int.random(in: 0..<cols), y: Int.random(in: 0..<rows))
        var attempts = 0
        while snakeSet.contains(candidate) && attempts < cols * rows {
            candidate = GridPoint(x: Int.random(in: 0..<cols), y: Int.random(in: 0..<rows))
            attempts += 1
        }
        apple = candidate
    }

    deinit { timer?.invalidate() }
}
