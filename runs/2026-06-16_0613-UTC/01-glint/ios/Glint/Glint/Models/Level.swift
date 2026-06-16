import SwiftUI

/// The kind of objective a level asks for.
enum GoalType: Codable, Hashable {
    /// Reach `target` score within the move limit.
    case score(target: Int)
    /// Clear `count` gems of `color` within the move limit.
    case clearColor(color: GemColor, count: Int)

    var icon: String {
        switch self {
        case .score: return "star.circle.fill"
        case .clearColor: return "circle.grid.cross.fill"
        }
    }
}

/// A hand-defined level. Star thresholds reward higher scores.
struct Level: Identifiable, Hashable {
    let id: Int          // 1-based level number
    let pack: Int        // pack index (0 = free starter pack)
    let rows: Int
    let cols: Int
    let moves: Int
    let goal: GoalType
    /// Score thresholds for 1, 2, 3 stars (ascending).
    let starThresholds: [Int]

    var title: String { "Level \(id)" }

    func stars(forScore score: Int) -> Int {
        var s = 0
        for t in starThresholds where score >= t { s += 1 }
        return min(3, s)
    }

    var goalText: String {
        switch goal {
        case .score(let target):
            return "Reach \(target) points in \(moves) moves"
        case .clearColor(let color, let count):
            return "Clear \(count) \(color.name) gems in \(moves) moves"
        }
    }

    var shortGoalText: String {
        switch goal {
        case .score(let target): return "\(target) pts"
        case .clearColor(let color, let count): return "\(count) \(color.name)"
        }
    }
}

/// The full level catalog. ~24 levels across packs; pack 0 (levels 1–8) is free.
enum LevelCatalog {
    static let freePackSize = 8

    static let all: [Level] = build()

    static func level(id: Int) -> Level? {
        all.first { $0.id == id }
    }

    static var packs: [Int: [Level]] {
        Dictionary(grouping: all, by: { $0.pack })
    }

    private static func build() -> [Level] {
        var levels: [Level] = []
        // Difficulty curve: scores ramp up, boards grow, color goals interleaved.
        let colorRotation: [GemColor] = [.ruby, .emerald, .sapphire, .citrine, .topaz, .amethyst]

        for i in 1...24 {
            let pack = (i - 1) / 8
            let size = i <= 8 ? 7 : (i <= 16 ? 8 : 8)
            let moves = max(14, 30 - i / 2)
            let baseScore = 700 + i * 220

            let goal: GoalType
            let thresholds: [Int]
            if i % 3 == 0 {
                // Every 3rd level is a color-clear goal.
                let color = colorRotation[(i / 3 - 1) % colorRotation.count]
                let count = 18 + i
                goal = .clearColor(color: color, count: count)
                // For color goals, stars still come from score earned.
                thresholds = [baseScore, baseScore + 600, baseScore + 1400]
            } else {
                goal = .score(target: baseScore)
                thresholds = [baseScore, baseScore + 700, baseScore + 1600]
            }
            levels.append(Level(id: i, pack: pack, rows: size, cols: size, moves: moves, goal: goal, starThresholds: thresholds))
        }
        return levels
    }
}
