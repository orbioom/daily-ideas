import Foundation

struct WaveEntry {
    let type: EnemyType
    let count: Int
    let spacing: Double
}

struct WaveConfig {
    let entries: [WaveEntry]

    static let waves: [WaveConfig] = [
        // Wave 1: 8 goblins
        WaveConfig(entries: [
            WaveEntry(type: .goblin, count: 8, spacing: 1.5)
        ]),
        // Wave 2: 5 goblins + 4 orcs
        WaveConfig(entries: [
            WaveEntry(type: .goblin, count: 5, spacing: 1.5),
            WaveEntry(type: .orc, count: 4, spacing: 2.0)
        ]),
        // Wave 3: 10 goblins + 6 orcs
        WaveConfig(entries: [
            WaveEntry(type: .goblin, count: 10, spacing: 1.2),
            WaveEntry(type: .orc, count: 6, spacing: 1.8)
        ]),
        // Wave 4: 5 orcs + 3 trolls
        WaveConfig(entries: [
            WaveEntry(type: .orc, count: 5, spacing: 1.8),
            WaveEntry(type: .troll, count: 3, spacing: 3.0)
        ]),
        // Wave 5: 10 goblins + 5 orcs + 3 trolls + 1 dragon (boss)
        WaveConfig(entries: [
            WaveEntry(type: .goblin, count: 10, spacing: 1.0),
            WaveEntry(type: .orc, count: 5, spacing: 1.5),
            WaveEntry(type: .troll, count: 3, spacing: 2.5),
            WaveEntry(type: .dragon, count: 1, spacing: 1.0)
        ])
    ]

    func buildSpawnQueue() -> [EnemyType] {
        var queue: [EnemyType] = []
        for entry in entries {
            for _ in 0..<entry.count {
                queue.append(entry.type)
            }
        }
        return queue
    }
}
