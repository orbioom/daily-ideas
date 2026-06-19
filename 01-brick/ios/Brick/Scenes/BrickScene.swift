import SpriteKit
import UIKit

protocol BrickSceneDelegate: AnyObject {
    func brickDestroyed(points: Int)
    func lifeLost()
    func powerUpCollected(_ kind: PowerUpKind)
}

private let categoryBall:    UInt32 = 0x1 << 0
private let categoryPaddle:  UInt32 = 0x1 << 1
private let categoryBrick:   UInt32 = 0x1 << 2
private let categoryWall:    UInt32 = 0x1 << 3
private let categoryPowerUp: UInt32 = 0x1 << 4

final class BrickScene: SKScene, SKPhysicsContactDelegate {

    weak var brickDelegate: BrickSceneDelegate?
    var level: BrickLayout = BrickLayout.levels[0]

    private var paddle: SKShapeNode!
    private var balls: [SKShapeNode] = []
    private var brickNodes: [SKShapeNode] = []
    private var brickHits: [SKShapeNode: Int] = [:]
    private var brickColors: [SKShapeNode: BrickColor] = [:]

    private let ballRadius: CGFloat = 9
    private var paddleWidth: CGFloat = 80
    private let paddleHeight: CGFloat = 14
    private let brickHeight: CGFloat = 20
    private let brickPad: CGFloat = 4

    private var widePaddleExpiry: TimeInterval = 0
    private var slowBallExpiry: TimeInterval = 0
    private var laserActive = false
    private var laserExpiry: TimeInterval = 0
    private var powerUpsOnScreen: [SKShapeNode: PowerUpKind] = [:]

    private var dragStartX: CGFloat = 0
    private var paddleStartX: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        setupWalls()
        setupPaddle()
        setupBricks()
    }

    func launchBall() {
        guard balls.isEmpty else { return }
        spawnBall(from: CGPoint(x: paddle.position.x, y: paddle.position.y + paddleHeight + ballRadius + 2))
    }

    private func spawnBall(from pos: CGPoint) {
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = .white
        ball.strokeColor = .clear
        ball.position = pos
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.friction = 0.0
        ball.physicsBody?.linearDamping = 0.0
        ball.physicsBody?.angularDamping = 0.0
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.categoryBitMask = categoryBall
        ball.physicsBody?.contactTestBitMask = categoryBrick | categoryPaddle | categoryPowerUp
        ball.physicsBody?.collisionBitMask = categoryWall | categoryPaddle | categoryBrick
        addChild(ball)
        balls.append(ball)

        let angle = CGFloat.random(in: (CGFloat.pi * 0.55)...(CGFloat.pi * 0.95))
        let speed: CGFloat = 360
        ball.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }

    // MARK: - Setup

    private func setupWalls() {
        let wallBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        wallBody.restitution = 1.0
        wallBody.friction = 0.0
        wallBody.categoryBitMask = categoryWall
        wallBody.collisionBitMask = categoryBall
        let walls = SKNode()
        walls.physicsBody = wallBody
        addChild(walls)
    }

    private func setupPaddle() {
        paddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 7)
        paddle.fillColor = SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
        paddle.strokeColor = .clear
        paddle.position = CGPoint(x: size.width / 2, y: 50)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: paddleWidth, height: paddleHeight))
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = categoryPaddle
        paddle.physicsBody?.collisionBitMask = categoryBall
        addChild(paddle)
    }

    private func setupBricks() {
        brickNodes.forEach { $0.removeFromParent() }
        brickNodes.removeAll()
        brickHits.removeAll()
        brickColors.removeAll()

        let layout = level
        let cols = layout.cols
        let rows = layout.rows
        let topMargin: CGFloat = 60
        let totalBrickW = size.width - 20
        let brickW = (totalBrickW - CGFloat(cols - 1) * brickPad) / CGFloat(cols)

        for row in 0..<rows {
            for col in 0..<cols {
                let hp = layout.grid[row][col]
                guard hp > 0 else { continue }
                let colorIdx = max(1, min(hp, 6))
                guard let brickColor = BrickColor(rawValue: colorIdx) else { continue }

                let x = 10 + CGFloat(col) * (brickW + brickPad) + brickW / 2
                let y = size.height - topMargin - CGFloat(row) * (brickHeight + brickPad) - brickHeight / 2

                let brick = SKShapeNode(rectOf: CGSize(width: brickW, height: brickHeight), cornerRadius: 4)
                brick.fillColor = brickColor.skColor
                brick.strokeColor = SKColor.white.withAlphaComponent(0.15)
                brick.lineWidth = 1
                brick.position = CGPoint(x: x, y: y)
                brick.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: brickW, height: brickHeight))
                brick.physicsBody?.isDynamic = false
                brick.physicsBody?.categoryBitMask = categoryBrick
                brick.physicsBody?.collisionBitMask = categoryBall
                brick.physicsBody?.contactTestBitMask = categoryBall
                addChild(brick)
                brickNodes.append(brick)
                brickHits[brick] = hp
                brickColors[brick] = brickColor
            }
        }
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.node
        let b = contact.bodyB.node

        if let ball = (a?.physicsBody?.categoryBitMask == categoryBall ? a : b) as? SKShapeNode,
           let brick = (a?.physicsBody?.categoryBitMask == categoryBrick ? a : b) as? SKShapeNode,
           brickNodes.contains(brick) {
            handleBallHitBrick(ball: ball, brick: brick)
        }

        if let powerUp = (a?.physicsBody?.categoryBitMask == categoryPowerUp ? a : b) as? SKShapeNode,
           let kind = powerUpsOnScreen[powerUp] {
            powerUp.removeFromParent()
            powerUpsOnScreen.removeValue(forKey: powerUp)
            brickDelegate?.powerUpCollected(kind)
            activatePowerUp(kind)
        }
    }

    private func handleBallHitBrick(ball: SKShapeNode, brick: SKShapeNode) {
        guard var hp = brickHits[brick] else { return }
        hp -= 1
        if hp <= 0 {
            let color = brickColors[brick] ?? .red
            brickHits.removeValue(forKey: brick)
            brickColors.removeValue(forKey: brick)
            if let idx = brickNodes.firstIndex(of: brick) { brickNodes.remove(at: idx) }
            brick.removeFromParent()
            brickDelegate?.brickDestroyed(points: color.points)
            if Int.random(in: 0..<5) == 0 { spawnPowerUp(at: brick.position) }
        } else {
            brickHits[brick] = hp
            let newColorIdx = max(1, min(hp, 6))
            if let newColor = BrickColor(rawValue: newColorIdx) {
                brick.fillColor = newColor.skColor
            }
            brick.run(SKAction.sequence([
                SKAction.scale(to: 1.12, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
        }
    }

    // MARK: - Power-ups

    private func spawnPowerUp(at pos: CGPoint) {
        guard let kind = PowerUpKind.allCases.randomElement() else { return }
        let node = SKShapeNode(rectOf: CGSize(width: 28, height: 18), cornerRadius: 4)
        node.fillColor = kind.color
        node.strokeColor = .clear
        node.position = pos
        let label = SKLabelNode(text: kind.symbol)
        label.fontSize = 11
        label.fontName = "AvenirNext-Bold"
        label.verticalAlignmentMode = .center
        label.fontColor = .black
        node.addChild(label)
        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 28, height: 18))
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.velocity = CGVector(dx: 0, dy: -80)
        node.physicsBody?.categoryBitMask = categoryPowerUp
        node.physicsBody?.contactTestBitMask = categoryPaddle
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
        powerUpsOnScreen[node] = kind
    }

    private func activatePowerUp(_ kind: PowerUpKind) {
        let now = currentTime
        switch kind {
        case .widePaddle:
            widePaddleExpiry = now + 10
            let wide = paddleWidth * 1.6
            let action = SKAction.resize(toWidth: wide, height: paddleHeight, duration: 0.2)
            paddle.run(action)
            paddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wide, height: paddleHeight))
            paddle.physicsBody?.isDynamic = false
            paddle.physicsBody?.categoryBitMask = categoryPaddle
            paddle.physicsBody?.collisionBitMask = categoryBall
        case .multiBall:
            if let first = balls.first {
                for _ in 0..<2 {
                    let offset = CGFloat.random(in: -20...20)
                    spawnBall(from: CGPoint(x: first.position.x + offset, y: first.position.y))
                }
            }
        case .laserPaddle:
            laserExpiry = now + 8
            laserActive = true
        case .slowBall:
            slowBallExpiry = now + 8
            balls.forEach {
                if let v = $0.physicsBody?.velocity {
                    $0.physicsBody?.velocity = CGVector(dx: v.dx * 0.6, dy: v.dy * 0.6)
                }
            }
        }
    }

    // MARK: - Update

    private var currentTime: TimeInterval = 0

    override func update(_ currentTime: TimeInterval) {
        self.currentTime = currentTime

        clampBallSpeed()
        removeFallenBalls()
        removeFallenPowerUps()

        if currentTime > widePaddleExpiry && paddleWidth != 80 {
            paddleWidth = 80
            paddle.run(SKAction.resize(toWidth: paddleWidth, height: paddleHeight, duration: 0.2))
            paddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: paddleWidth, height: paddleHeight))
            paddle.physicsBody?.isDynamic = false
            paddle.physicsBody?.categoryBitMask = categoryPaddle
            paddle.physicsBody?.collisionBitMask = categoryBall
        }
        if currentTime > laserExpiry { laserActive = false }
    }

    private func clampBallSpeed() {
        let minSpeed: CGFloat = slowBallExpiry > currentTime ? 200 : 320
        let maxSpeed: CGFloat = slowBallExpiry > currentTime ? 280 : 520
        for ball in balls {
            guard let body = ball.physicsBody else { continue }
            let speed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
            if speed < minSpeed || speed > maxSpeed {
                let target = speed < minSpeed ? minSpeed : maxSpeed
                let scale = target / max(speed, 1)
                body.velocity = CGVector(dx: body.velocity.dx * scale, dy: body.velocity.dy * scale)
            }
        }
    }

    private func removeFallenBalls() {
        let fallen = balls.filter { $0.position.y < -30 }
        fallen.forEach { $0.removeFromParent() }
        balls.removeAll { $0.position.y < -30 }
        if balls.isEmpty {
            brickDelegate?.lifeLost()
        }
    }

    private func removeFallenPowerUps() {
        let fallen = powerUpsOnScreen.keys.filter { $0.position.y < -30 }
        fallen.forEach {
            $0.removeFromParent()
            powerUpsOnScreen.removeValue(forKey: $0)
        }
    }

    // MARK: - Touch/Drag

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        dragStartX = loc.x
        paddleStartX = paddle.position.x

        if laserActive {
            fireLaser()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let delta = loc.x - dragStartX
        let half = paddleWidth / 2
        paddle.position.x = max(half, min(size.width - half, paddleStartX + delta))
    }

    private func fireLaser() {
        let laser = SKShapeNode(rectOf: CGSize(width: 3, height: 20))
        laser.fillColor = .red
        laser.strokeColor = .clear
        laser.position = CGPoint(x: paddle.position.x, y: paddle.position.y + paddleHeight + 10)
        addChild(laser)
        laser.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: size.height, duration: 0.4),
            SKAction.removeFromParent()
        ]))
    }

    func resetLevel() {
        balls.forEach { $0.removeFromParent() }
        balls.removeAll()
        powerUpsOnScreen.keys.forEach { $0.removeFromParent() }
        powerUpsOnScreen.removeAll()
        paddle.position = CGPoint(x: size.width / 2, y: 50)
        setupBricks()
    }

    func nextLevel(_ layout: BrickLayout) {
        self.level = layout
        resetLevel()
    }
}
