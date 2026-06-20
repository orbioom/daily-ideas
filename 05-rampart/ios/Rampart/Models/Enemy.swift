import Foundation

struct Enemy: Identifiable {
    var id = UUID()
    var type: EnemyType
    var position: CGPoint = .zero
    var pathIndex: Int = 0
    var hp: Double
    var maxHp: Double
    var speed: Double         // current movement speed in game-space units/sec
    var baseSpeed: Double     // unmodified speed for frost restoration
    var frosted: Bool = false
    var frostTimer: Double = 0.0  // remaining seconds of frost effect
    var reward: Int

    var hpFraction: Double { max(0, hp / maxHp) }

    init(type: EnemyType) {
        self.type = type
        self.hp = type.baseHP
        self.maxHp = type.baseHP
        self.speed = type.baseSpeed
        self.baseSpeed = type.baseSpeed
        self.reward = type.reward
    }
}
