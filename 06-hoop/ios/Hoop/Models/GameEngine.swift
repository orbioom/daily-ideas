import Foundation
import SwiftData
import Observation

// MARK: - Supporting Types

struct PlayerState: Identifiable {
    let id = UUID()
    var name: String
    var number: String
    var points2: Int = 0
    var points3: Int = 0
    var ftMade: Int = 0
    var ftAttempted: Int = 0
    var fouls: Int = 0
    var totalPoints: Int { points2 * 2 + points3 * 3 + ftMade }
}

struct GameSetup {
    var teamAName: String = "Home"
    var teamBName: String = "Away"
    var teamAPlayers: [(name: String, number: String)] = []
    var teamBPlayers: [(name: String, number: String)] = []
    var quarters: Int = 4
    var quarterMinutes: Int = 10
    var timeoutsPerTeam: Int = 5
}

struct ActionRecord {
    enum ActionType {
        case score2(playerID: UUID, team: String)
        case score3(playerID: UUID, team: String)
        case ftMade(playerID: UUID, team: String)
        case ftMissed(playerID: UUID, team: String)
        case foul(team: String)
        case timeout(team: String)
    }
    let type: ActionType
}

// MARK: - GameEngine

@Observable final class GameEngine {
    var teamAName: String
    var teamBName: String
    var currentQuarter: Int = 1
    var totalQuarters: Int
    var quarterMinutes: Int

    var scoreA: Int = 0
    var scoreB: Int = 0
    var quarterScoresA: [Int] = []
    var quarterScoresB: [Int] = []

    var teamAPlayers: [PlayerState] = []
    var teamBPlayers: [PlayerState] = []

    var teamAFouls: Int = 0
    var teamBFouls: Int = 0
    var teamATimeouts: Int
    var teamBTimeouts: Int

    var isGameOver: Bool = false

    // Timer
    var secondsRemaining: Int
    var isRunning: Bool = false
    private var timerTask: Task<Void, Never>?

    // Undo
    private var actionStack: [ActionRecord] = []

    init(setup: GameSetup) {
        self.teamAName = setup.teamAName
        self.teamBName = setup.teamBName
        self.totalQuarters = setup.quarters
        self.quarterMinutes = setup.quarterMinutes
        self.teamATimeouts = setup.timeoutsPerTeam
        self.teamBTimeouts = setup.timeoutsPerTeam
        self.secondsRemaining = setup.quarterMinutes * 60

        self.teamAPlayers = setup.teamAPlayers.map {
            PlayerState(name: $0.name, number: $0.number)
        }
        self.teamBPlayers = setup.teamBPlayers.map {
            PlayerState(name: $0.name, number: $0.number)
        }

        self.quarterScoresA = [Int](repeating: 0, count: setup.quarters)
        self.quarterScoresB = [Int](repeating: 0, count: setup.quarters)
    }

    // MARK: - Timer

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        timerTask = Task {
            while secondsRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if isRunning {
                    secondsRemaining -= 1
                }
            }
            if secondsRemaining == 0 {
                isRunning = false
            }
        }
    }

    func pauseTimer() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func endQuarter() {
        pauseTimer()
        // Record quarter score
        let qIndex = currentQuarter - 1
        if qIndex < quarterScoresA.count {
            quarterScoresA[qIndex] = scoreA - quarterScoresA[0..<qIndex].reduce(0, +)
            quarterScoresB[qIndex] = scoreB - quarterScoresB[0..<qIndex].reduce(0, +)
        }

        if currentQuarter >= totalQuarters {
            isGameOver = true
        } else {
            currentQuarter += 1
            secondsRemaining = quarterMinutes * 60
            // Reset team fouls per quarter
            teamAFouls = 0
            teamBFouls = 0
        }
    }

    // MARK: - Scoring

    func add2pt(player: PlayerState, team: String) {
        guard !isGameOver else { return }
        guard let idx = playerIndex(id: player.id, team: team) else { return }
        mutatePlayer(index: idx, team: team) { p in p.points2 += 1 }
        if team == "A" { scoreA += 2 } else { scoreB += 2 }
        actionStack.append(ActionRecord(type: .score2(playerID: player.id, team: team)))
    }

    func add3pt(player: PlayerState, team: String) {
        guard !isGameOver else { return }
        guard let idx = playerIndex(id: player.id, team: team) else { return }
        mutatePlayer(index: idx, team: team) { p in p.points3 += 1 }
        if team == "A" { scoreA += 3 } else { scoreB += 3 }
        actionStack.append(ActionRecord(type: .score3(playerID: player.id, team: team)))
    }

    func addFreeThrow(player: PlayerState, team: String, made: Bool) {
        guard !isGameOver else { return }
        guard let idx = playerIndex(id: player.id, team: team) else { return }
        mutatePlayer(index: idx, team: team) { p in
            p.ftAttempted += 1
            if made { p.ftMade += 1 }
        }
        if made {
            if team == "A" { scoreA += 1 } else { scoreB += 1 }
            actionStack.append(ActionRecord(type: .ftMade(playerID: player.id, team: team)))
        } else {
            actionStack.append(ActionRecord(type: .ftMissed(playerID: player.id, team: team)))
        }
    }

    func addFoul(player: PlayerState, team: String) {
        guard !isGameOver else { return }
        guard let idx = playerIndex(id: player.id, team: team) else { return }
        mutatePlayer(index: idx, team: team) { p in p.fouls += 1 }
        if team == "A" { teamAFouls += 1 } else { teamBFouls += 1 }
        actionStack.append(ActionRecord(type: .foul(team: team)))
    }

    func useTimeout(team: String) {
        if team == "A" && teamATimeouts > 0 {
            teamATimeouts -= 1
            actionStack.append(ActionRecord(type: .timeout(team: team)))
        } else if team == "B" && teamBTimeouts > 0 {
            teamBTimeouts -= 1
            actionStack.append(ActionRecord(type: .timeout(team: team)))
        }
    }

    // MARK: - Undo

    func undoLastAction() {
        guard let last = actionStack.popLast() else { return }
        switch last.type {
        case .score2(let pid, let team):
            if let idx = playerIndex(id: pid, team: team) {
                mutatePlayer(index: idx, team: team) { p in p.points2 = max(0, p.points2 - 1) }
            }
            if team == "A" { scoreA = max(0, scoreA - 2) } else { scoreB = max(0, scoreB - 2) }

        case .score3(let pid, let team):
            if let idx = playerIndex(id: pid, team: team) {
                mutatePlayer(index: idx, team: team) { p in p.points3 = max(0, p.points3 - 1) }
            }
            if team == "A" { scoreA = max(0, scoreA - 3) } else { scoreB = max(0, scoreB - 3) }

        case .ftMade(let pid, let team):
            if let idx = playerIndex(id: pid, team: team) {
                mutatePlayer(index: idx, team: team) { p in
                    p.ftMade = max(0, p.ftMade - 1)
                    p.ftAttempted = max(0, p.ftAttempted - 1)
                }
            }
            if team == "A" { scoreA = max(0, scoreA - 1) } else { scoreB = max(0, scoreB - 1) }

        case .ftMissed(let pid, let team):
            if let idx = playerIndex(id: pid, team: team) {
                mutatePlayer(index: idx, team: team) { p in
                    p.ftAttempted = max(0, p.ftAttempted - 1)
                }
            }

        case .foul(let team):
            if team == "A" { teamAFouls = max(0, teamAFouls - 1) } else { teamBFouls = max(0, teamBFouls - 1) }
            // Note: individual player foul undo not tracked in ActionRecord foul case without playerID

        case .timeout(let team):
            if team == "A" { teamATimeouts += 1 } else { teamBTimeouts += 1 }
        }
    }

    // MARK: - Persistence

    func saveToContext(_ ctx: ModelContext) {
        let game = HoopGame(
            teamAName: teamAName,
            teamBName: teamBName,
            quarters: totalQuarters,
            quarterMinutes: quarterMinutes
        )
        game.isComplete = true

        // Compute final quarter scores
        var qScoresA = [Int](repeating: 0, count: totalQuarters)
        var qScoresB = [Int](repeating: 0, count: totalQuarters)
        for i in 0..<min(quarterScoresA.count, totalQuarters) {
            qScoresA[i] = quarterScoresA[i]
            qScoresB[i] = quarterScoresB[i]
        }
        // Fill last quarter with remaining score
        let lastIdx = totalQuarters - 1
        let sumA = qScoresA[0..<lastIdx].reduce(0, +)
        let sumB = qScoresB[0..<lastIdx].reduce(0, +)
        qScoresA[lastIdx] = max(0, scoreA - sumA)
        qScoresB[lastIdx] = max(0, scoreB - sumB)

        game.encodeQuarterScores(a: qScoresA, b: qScoresB)
        ctx.insert(game)

        // Save players
        for ps in teamAPlayers {
            let player = HoopPlayer(name: ps.name, number: ps.number, team: "A")
            player.points2 = ps.points2
            player.points3 = ps.points3
            player.freeThrowsMade = ps.ftMade
            player.freeThrowsAttempted = ps.ftAttempted
            player.fouls = ps.fouls
            player.game = game
            ctx.insert(player)
        }
        for ps in teamBPlayers {
            let player = HoopPlayer(name: ps.name, number: ps.number, team: "B")
            player.points2 = ps.points2
            player.points3 = ps.points3
            player.freeThrowsMade = ps.ftMade
            player.freeThrowsAttempted = ps.ftAttempted
            player.fouls = ps.fouls
            player.game = game
            ctx.insert(player)
        }

        do {
            try ctx.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    // MARK: - Helpers

    var canUndo: Bool { !actionStack.isEmpty }

    var timeString: String {
        let mins = secondsRemaining / 60
        let secs = secondsRemaining % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var quarterLabel: String {
        let suffix: String
        switch currentQuarter {
        case 1: suffix = totalQuarters == 2 ? "1st Half" : "1st Qtr"
        case 2: suffix = totalQuarters == 2 ? "2nd Half" : "2nd Qtr"
        case 3: suffix = "3rd Qtr"
        case 4: suffix = "4th Qtr"
        default: suffix = "OT"
        }
        return suffix
    }

    private func playerIndex(id: UUID, team: String) -> Int? {
        if team == "A" {
            return teamAPlayers.firstIndex(where: { $0.id == id })
        } else {
            return teamBPlayers.firstIndex(where: { $0.id == id })
        }
    }

    private func mutatePlayer(index: Int, team: String, mutation: (inout PlayerState) -> Void) {
        if team == "A" {
            mutation(&teamAPlayers[index])
        } else {
            mutation(&teamBPlayers[index])
        }
    }
}
