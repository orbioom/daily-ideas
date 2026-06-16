import Foundation

/// Everything needed to start a game. Built by the New Game screen, consumed by GameView.
struct GameConfig: Identifiable {
    let id = UUID()
    let mode: GameMode
    let players: [PlayerState]
    let seed: UInt64
    /// For Daily, the day key the result should be saved under.
    let dailyKey: String?

    static func solo(name: String = "You") -> GameConfig {
        GameConfig(mode: .solo,
                   players: [PlayerState(name: name.isEmpty ? "You" : name, isCPU: false, cpuDifficulty: nil)],
                   seed: UInt64.random(in: 1...UInt64.max),
                   dailyKey: nil)
    }

    static func passAndPlay(names: [String]) -> GameConfig {
        let players = names.enumerated().map { idx, n in
            PlayerState(name: n.isEmpty ? "Player \(idx + 1)" : n, isCPU: false, cpuDifficulty: nil)
        }
        return GameConfig(mode: .passAndPlay, players: players,
                          seed: UInt64.random(in: 1...UInt64.max), dailyKey: nil)
    }

    static func vsCPU(playerName: String, cpuCount: Int, difficulty: CPUDifficulty) -> GameConfig {
        var players: [PlayerState] = [PlayerState(name: playerName.isEmpty ? "You" : playerName,
                                                  isCPU: false, cpuDifficulty: nil)]
        let cpuNames = ["Pip", "Domino", "Ivory", "Felt"]
        for i in 0..<max(1, min(3, cpuCount)) {
            let base = cpuNames.indices.contains(i) ? cpuNames[i] : "CPU"
            players.append(PlayerState(name: "\(base) CPU", isCPU: true, cpuDifficulty: difficulty))
        }
        return GameConfig(mode: .vsCPU, players: players,
                          seed: UInt64.random(in: 1...UInt64.max), dailyKey: nil)
    }

    static func daily(name: String, date: Date) -> GameConfig {
        GameConfig(mode: .daily,
                   players: [PlayerState(name: name.isEmpty ? "You" : name, isCPU: false, cpuDifficulty: nil)],
                   seed: DailySeed.seed(for: date),
                   dailyKey: DailySeed.key(for: date))
    }
}
