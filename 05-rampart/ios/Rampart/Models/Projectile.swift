import Foundation

struct Projectile: Identifiable {
    var id = UUID()
    var position: CGPoint
    var targetEnemyID: UUID
    var type: TowerType
    var damage: Double
    var speed: Double = 200.0
    var splashRadius: Double
    var slowFactor: Double
}
