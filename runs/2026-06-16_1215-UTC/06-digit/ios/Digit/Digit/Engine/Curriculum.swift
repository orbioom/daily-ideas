import Foundation

/// A learning level: a named band of facts defined by its operations and number range.
struct Level: Identifiable, Equatable {
    let id: Int           // index in the ordered curriculum
    let title: String
    let subtitle: String
    let ops: [MathOp]
    let maxNumber: Int
    /// True if this level requires Digit Pro (anything involving × or ÷, or higher bands).
    let requiresPro: Bool
    let emoji: String

    static func == (lhs: Level, rhs: Level) -> Bool { lhs.id == rhs.id }
}

/// The ordered Digit curriculum. Pure, deterministic.
enum Curriculum {
    static let levels: [Level] = [
        Level(id: 0, title: "Add within 10",
              subtitle: "Sums up to 10 — the foundation",
              ops: [.add], maxNumber: 10, requiresPro: false, emoji: "🌱"),
        Level(id: 1, title: "Add within 20",
              subtitle: "Bigger sums, crossing ten",
              ops: [.add], maxNumber: 20, requiresPro: false, emoji: "🌿"),
        Level(id: 2, title: "Subtract within 20",
              subtitle: "Take-away facts to 20",
              ops: [.sub], maxNumber: 20, requiresPro: false, emoji: "🍃"),
        Level(id: 3, title: "Add & subtract to 20",
              subtitle: "Mix it up within twenty",
              ops: [.add, .sub], maxNumber: 20, requiresPro: false, emoji: "🌳"),
        Level(id: 4, title: "×2 ×5 ×10",
              subtitle: "The friendly times tables",
              ops: [.mul], maxNumber: 10, requiresPro: true, emoji: "⭐️"),
        Level(id: 5, title: "All times tables",
              subtitle: "Every fact up to 12 × 12",
              ops: [.mul], maxNumber: 12, requiresPro: true, emoji: "🚀"),
        Level(id: 6, title: "Division facts",
              subtitle: "Sharing equally, to 12",
              ops: [.div], maxNumber: 12, requiresPro: true, emoji: "🪐"),
        Level(id: 7, title: "Mixed mastery",
              subtitle: "All four operations together",
              ops: [.add, .sub, .mul, .div], maxNumber: 12, requiresPro: true, emoji: "🏆")
    ]

    static func level(at index: Int) -> Level {
        guard levels.indices.contains(index) else {
            return levels.first ?? Level(id: 0, title: "Practice", subtitle: "",
                                         ops: [.add], maxNumber: 10, requiresPro: false, emoji: "🌱")
        }
        return levels[index]
    }

    static var count: Int { levels.count }

    /// Mastery fraction (0...1) required to consider a level "passed".
    static let passThreshold = 0.75

    /// Special level id meaning "subtract from the level's range with the special ×2/×5/×10 set".
    static let easyMulMultipliers: Set<Int> = [2, 5, 10]
}
