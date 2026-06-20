import Foundation
import SwiftUI

enum GamePhase {
    case prepare
    case wave
    case waveComplete
    case gameOver
    case victory
}

@Observable
final class RampartGame {
    // Map
    var map: GameMap
    var towers: [Tower] = []
    var enemies: [Enemy] = []
    var projectiles: [Projectile] = []

    // Player state
    var coins: Int = 150
    var lives: Int = 20
    var score: Int = 0
    var wave: Int = 0
    var totalWaves: Int = 5

    // Game state
    var phase: GamePhase = .prepare
    var gameTime: TimeInterval = 0.0
    var lastUpdateTime: TimeInterval = 0.0
    var selectedTowerType: TowerType = .archer
    var selectedCell: (col: Int, row: Int)? = nil
    var isSpawning: Bool = false
    var spawnQueue: [EnemyType] = []
    var nextSpawnTime: TimeInterval = 0.0
    var spawnInterval: Double = 1.5

    init(map: GameMap) {
        self.map = map
    }

    // MARK: - Public Interface

    func update(timestamp: TimeInterval) {
        guard phase == .wave else { return }
        if lastUpdateTime == 0 { lastUpdateTime = timestamp }
        let dt = min(timestamp - lastUpdateTime, 0.05)
        lastUpdateTime = timestamp
        gameTime += dt

        spawnNextEnemy(currentTime: timestamp)
        moveEnemies(dt: dt)
        updateFrost(dt: dt)
        fireTowers(currentTime: timestamp)
        moveProjectiles(dt: dt)
        checkProjectileHits()
        removeDeadEnemies()
        checkWaveCompletion()
    }

    func startWave() {
        guard phase == .prepare || phase == .waveComplete else { return }
        wave += 1
        guard wave <= totalWaves else { return }
        let waveIndex = wave - 1
        guard waveIndex < WaveConfig.waves.count else { return }
        let config = WaveConfig.waves[waveIndex]
        spawnQueue = config.buildSpawnQueue()
        isSpawning = true
        nextSpawnTime = 0
        phase = .wave
    }

    func placeSelectedTower(at cell: (col: Int, row: Int)) {
        guard canBuild(at: cell) else { return }
        guard coins >= selectedTowerType.cost else { return }
        let pos = cellCenter(col: cell.col, row: cell.row)
        let tower = Tower(type: selectedTowerType, position: pos, cell: cell)
        towers.append(tower)
        coins -= selectedTowerType.cost
        // Mark cell as not buildable
        if cell.row < map.cells.count && cell.col < map.cells[cell.row].count {
            map.cells[cell.row][cell.col].isBuildable = false
        }
    }

    func sellTower(at cell: (col: Int, row: Int)) -> Int {
        guard let idx = towers.firstIndex(where: { $0.cell.col == cell.col && $0.cell.row == cell.row }) else { return 0 }
        let refund = towers[idx].type.cost / 2
        towers.remove(at: idx)
        coins += refund
        if cell.row < map.cells.count && cell.col < map.cells[cell.row].count {
            map.cells[cell.row][cell.col].isBuildable = true
        }
        return refund
    }

    func hasTower(at cell: (col: Int, row: Int)) -> Tower? {
        towers.first(where: { $0.cell.col == cell.col && $0.cell.row == cell.row })
    }

    func canBuild(at cell: (col: Int, row: Int)) -> Bool {
        guard cell.row >= 0, cell.row < map.cells.count,
              cell.col >= 0, cell.col < map.cells[cell.row].count else { return false }
        let gc = map.cells[cell.row][cell.col]
        guard gc.isBuildable else { return false }
        guard hasTower(at: cell) == nil else { return false }
        return true
    }

    // MARK: - Private Helpers

    private func cellCenter(col: Int, row: Int) -> CGPoint {
        CGPoint(x: Double(col) * 20.0 + 10.0, y: Double(row) * 20.0 + 10.0)
    }

    private func moveEnemies(dt: Double) {
        let path = map.path
        guard path.count >= 2 else { return }
        var toRemove: [UUID] = []

        for i in enemies.indices {
            var enemy = enemies[i]
            var remaining = enemy.speed * dt

            while remaining > 0 {
                let targetIndex = enemy.pathIndex + 1
                if targetIndex >= path.count {
                    // Reached exit
                    lives = max(0, lives - 1)
                    toRemove.append(enemy.id)
                    remaining = 0
                    break
                }
                let target = path[targetIndex]
                let dx = target.x - enemy.position.x
                let dy = target.y - enemy.position.y
                let dist = sqrt(dx * dx + dy * dy)

                if dist <= remaining {
                    // Move to waypoint and continue
                    enemy.position = target
                    enemy.pathIndex = targetIndex
                    remaining -= dist
                } else {
                    // Move toward waypoint
                    let factor = remaining / dist
                    enemy.position.x += dx * factor
                    enemy.position.y += dy * factor
                    remaining = 0
                }
            }
            enemies[i] = enemy
        }

        enemies.removeAll { toRemove.contains($0.id) }
        if lives <= 0 { phase = .gameOver }
    }

    private func updateFrost(dt: Double) {
        for i in enemies.indices {
            if enemies[i].frosted {
                enemies[i].frostTimer -= dt
                if enemies[i].frostTimer <= 0 {
                    enemies[i].frosted = false
                    enemies[i].frostTimer = 0
                    enemies[i].speed = enemies[i].baseSpeed
                }
            }
        }
    }

    private func fireTowers(currentTime: TimeInterval) {
        for i in towers.indices {
            let tower = towers[i]
            guard currentTime - tower.lastFiredTime >= tower.type.fireRate else { continue }
            guard let target = findTarget(for: tower) else { continue }
            let projectile = Projectile(
                position: tower.position,
                targetEnemyID: target.id,
                type: tower.type,
                damage: tower.type.damage,
                splashRadius: tower.type.splashRadius,
                slowFactor: tower.type.slowFactor
            )
            projectiles.append(projectile)
            towers[i].lastFiredTime = currentTime
        }
    }

    private func findTarget(for tower: Tower) -> Enemy? {
        var bestEnemy: Enemy? = nil
        var bestDist = Double.infinity

        for enemy in enemies {
            let dx = enemy.position.x - tower.position.x
            let dy = enemy.position.y - tower.position.y
            let dist = sqrt(dx * dx + dy * dy)
            guard dist <= tower.type.range else { continue }

            // For frost towers, prefer non-frosted enemies
            if tower.type == .frost && enemy.frosted { continue }

            if dist < bestDist {
                bestDist = dist
                bestEnemy = enemy
            }
        }

        // If frost found no non-frosted target, allow already-frosted
        if tower.type == .frost && bestEnemy == nil {
            for enemy in enemies {
                let dx = enemy.position.x - tower.position.x
                let dy = enemy.position.y - tower.position.y
                let dist = sqrt(dx * dx + dy * dy)
                guard dist <= tower.type.range else { continue }
                if dist < bestDist {
                    bestDist = dist
                    bestEnemy = enemy
                }
            }
        }

        return bestEnemy
    }

    private func moveProjectiles(dt: Double) {
        var toRemove: [UUID] = []
        for i in projectiles.indices {
            let targetExists = enemies.contains(where: { $0.id == projectiles[i].targetEnemyID })
            if !targetExists {
                toRemove.append(projectiles[i].id)
                continue
            }
            guard let target = enemies.first(where: { $0.id == projectiles[i].targetEnemyID }) else {
                toRemove.append(projectiles[i].id)
                continue
            }
            let dx = target.position.x - projectiles[i].position.x
            let dy = target.position.y - projectiles[i].position.y
            let dist = sqrt(dx * dx + dy * dy)
            let moveDist = projectiles[i].speed * dt
            if dist <= moveDist {
                projectiles[i].position = target.position
            } else {
                let factor = moveDist / dist
                projectiles[i].position.x += dx * factor
                projectiles[i].position.y += dy * factor
            }
        }
        projectiles.removeAll { toRemove.contains($0.id) }
    }

    private func checkProjectileHits() {
        var toRemove: [UUID] = []
        for proj in projectiles {
            guard let targetIdx = enemies.firstIndex(where: { $0.id == proj.targetEnemyID }) else {
                toRemove.append(proj.id)
                continue
            }
            let target = enemies[targetIdx]
            let dx = target.position.x - proj.position.x
            let dy = target.position.y - proj.position.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist <= 8.0 {
                applyDamage(
                    enemyID: proj.targetEnemyID,
                    damage: proj.damage,
                    isSplash: proj.splashRadius > 0,
                    splashRadius: proj.splashRadius,
                    slowFactor: proj.slowFactor
                )
                toRemove.append(proj.id)
            }
        }
        projectiles.removeAll { toRemove.contains($0.id) }
    }

    private func applyDamage(enemyID: UUID, damage: Double, isSplash: Bool, splashRadius: Double, slowFactor: Double) {
        guard let hitIdx = enemies.firstIndex(where: { $0.id == enemyID }) else { return }
        let hitPos = enemies[hitIdx].position

        // Direct damage
        enemies[hitIdx].hp -= damage
        applySlowIfNeeded(idx: hitIdx, slowFactor: slowFactor)

        // Splash damage
        if isSplash && splashRadius > 0 {
            for i in enemies.indices where i != hitIdx {
                let dx = enemies[i].position.x - hitPos.x
                let dy = enemies[i].position.y - hitPos.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist <= splashRadius {
                    enemies[i].hp -= damage * 0.5
                }
            }
        }
    }

    private func applySlowIfNeeded(idx: Int, slowFactor: Double) {
        guard slowFactor < 1.0 else { return }
        if !enemies[idx].frosted {
            enemies[idx].frosted = true
            enemies[idx].speed = enemies[idx].baseSpeed * slowFactor
        }
        enemies[idx].frostTimer = max(enemies[idx].frostTimer, 2.0)
    }

    private func removeDeadEnemies() {
        let dead = enemies.filter { $0.hp <= 0 }
        for d in dead {
            coins += d.reward
            score += d.reward * 10
        }
        enemies.removeAll { $0.hp <= 0 }
    }

    private func spawnNextEnemy(currentTime: TimeInterval) {
        guard isSpawning, !spawnQueue.isEmpty else {
            if isSpawning && spawnQueue.isEmpty { isSpawning = false }
            return
        }
        if nextSpawnTime == 0 { nextSpawnTime = currentTime }
        guard currentTime >= nextSpawnTime else { return }
        let type = spawnQueue.removeFirst()
        var enemy = Enemy(type: type)
        enemy.position = map.path.first ?? CGPoint(x: 160, y: 10)
        enemies.append(enemy)
        nextSpawnTime = currentTime + spawnInterval
        if spawnQueue.isEmpty { isSpawning = false }
    }

    private func checkWaveCompletion() {
        guard !isSpawning, enemies.isEmpty, projectiles.isEmpty else { return }
        guard phase == .wave else { return }
        if wave >= totalWaves {
            phase = .victory
        } else {
            phase = .waveComplete
            // Bonus coins between waves
            coins += 25 + wave * 5
        }
    }

    func reset() {
        towers = []
        enemies = []
        projectiles = []
        coins = 150
        lives = 20
        score = 0
        wave = 0
        phase = .prepare
        gameTime = 0
        lastUpdateTime = 0
        isSpawning = false
        spawnQueue = []
        nextSpawnTime = 0
    }
}
