import Foundation
import SwiftUI

// MARK: - Pack Definition

struct LevelPack: Identifiable {
    let id: Int
    let name: String
    let description: String
    let levelRange: ClosedRange<Int>
    let requiresPro: Bool

    var levels: [SokobanLevel] {
        allLevels.filter { $0.packId == id }
    }

    var levelCount: Int { levels.count }
}

// MARK: - All Packs

let allPacks: [LevelPack] = [
    LevelPack(
        id: 1,
        name: "Tutorial",
        description: "Learn the basics. Push each box directly to its target.",
        levelRange: 1...10,
        requiresPro: false
    ),
    LevelPack(
        id: 2,
        name: "Classic",
        description: "Classic warehouse-style puzzles. Plan ahead.",
        levelRange: 11...20,
        requiresPro: false
    ),
    LevelPack(
        id: 3,
        name: "Hard",
        description: "Sophisticated moves required. Think twice.",
        levelRange: 21...30,
        requiresPro: false
    ),
    LevelPack(
        id: 4,
        name: "Expert",
        description: "Pro-level only. These will test your limits.",
        levelRange: 31...40,
        requiresPro: true
    ),
    LevelPack(
        id: 5,
        name: "Daily",
        description: "A fresh puzzle every day. Keep your streak going.",
        levelRange: 41...50,
        requiresPro: false
    )
]

// MARK: - Daily Level Selection

struct DailyLevelPicker {
    static let dailyLevels: [SokobanLevel] = allLevels.filter { $0.packId == 5 }

    static func level(for date: Date = Date()) -> SokobanLevel {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        // Simple deterministic seed from date
        let seed = (components.year ?? 2024) * 10000
                 + (components.month ?? 1) * 100
                 + (components.day ?? 1)
        let index = seed % dailyLevels.count
        return dailyLevels[index]
    }

    static func dateString(for date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
