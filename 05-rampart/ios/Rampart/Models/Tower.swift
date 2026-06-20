import Foundation

struct Tower: Identifiable {
    var id = UUID()
    var type: TowerType
    var position: CGPoint
    var cell: (col: Int, row: Int)
    var lastFiredTime: TimeInterval = 0
    var level: Int = 1

    var effectiveDamage: Double { type.damage * Double(level) }
    var effectiveRange: Double  { type.range * (level > 1 ? 1.15 : 1.0) }
}
