import SwiftUI
import SwiftData

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

@Observable final class GameEngine {
    var teamAName: String
    var teamBName: String
    var totalQuarters: Int
    var quarterMinutes: Int
    
    var currentQuarter: Int = 1
    var scoreA: Int = 0
    var scoreB: Int = 0
    var quarterScoresA: [Int] = []
    var quarterScoresB: [Int] = []
    var currentQScoreA: Int = 0
    var currentQScoreB: Int = 0
    
    var teamAPlayers: [PlayerState]
    var teamBPlayers: [PlayerState]
    var teamAFouls: Int = 0
    var teamBFouls: Int = 0
    var teamATimeoutsLeft: Int
    var teamBTimeoutsLeft: Int
    
    var secondsRemaining: Int
    var isRunning: Bool = false
    var isGameOver: Bool = false
    
    private var timerTask: Task<Void, Never>?
    
    // Undo
    private struct ActionSnapshot {
        var scoreA: Int; var scoreB: Int
        var teamAPlayers: [PlayerState]; var teamBPlayers: [PlayerState]
        var teamAFouls: Int; var teamBFouls: Int
        var teamATimeouts: Int; var teamBTimeouts: Int
        var currentQScoreA: Int; var currentQScoreB: Int
    }
    private var undoStack: [ActionSnapshot] = []
    
    init(setup: GameSetup) {
        teamAName = setup.teamAName; teamBName = setup.teamBName
        totalQuarters = setup.quarters; quarterMinutes = setup.quarterMinutes
        secondsRemaining = setup.quarterMinutes * 60
        teamATimeoutsLeft = setup.timeoutsPerTeam; teamBTimeoutsLeft = setup.timeoutsPerTeam
        teamAPlayers = setup.teamAPlayers.map { PlayerState(name: $0.name, number: $0.number) }
        teamBPlayers = setup.teamBPlayers.map { PlayerState(name: $0.name, number: $0.number) }
    }
    
    func startTimer() {
        guard !isRunning, secondsRemaining > 0 else { return }
        isRunning = true
        timerTask = Task { @MainActor in
            while secondsRemaining > 0 && isRunning && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if isRunning && secondsRemaining > 0 {
                    secondsRemaining -= 1
                    if secondsRemaining == 0 { isRunning = false }
                }
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timerTask?.cancel()
    }
    
    func endQuarter() {
        pauseTimer()
        quarterScoresA.append(currentQScoreA)
        quarterScoresB.append(currentQScoreB)
        currentQScoreA = 0; currentQScoreB = 0
        if currentQuarter >= totalQuarters {
            isGameOver = true
        } else {
            currentQuarter += 1
            secondsRemaining = quarterMinutes * 60
        }
    }
    
    private func pushUndo() {
        let snap = ActionSnapshot(scoreA: scoreA, scoreB: scoreB,
            teamAPlayers: teamAPlayers, teamBPlayers: teamBPlayers,
            teamAFouls: teamAFouls, teamBFouls: teamBFouls,
            teamATimeouts: teamATimeoutsLeft, teamBTimeouts: teamBTimeoutsLeft,
            currentQScoreA: currentQScoreA, currentQScoreB: currentQScoreB)
        undoStack.append(snap)
        if undoStack.count > 30 { undoStack.removeFirst() }
    }
    
    func undoLastAction() {
        guard let snap = undoStack.popLast() else { return }
        scoreA = snap.scoreA; scoreB = snap.scoreB
        teamAPlayers = snap.teamAPlayers; teamBPlayers = snap.teamBPlayers
        teamAFouls = snap.teamAFouls; teamBFouls = snap.teamBFouls
        teamATimeoutsLeft = snap.teamATimeouts; teamBTimeoutsLeft = snap.teamBTimeouts
        currentQScoreA = snap.currentQScoreA; currentQScoreB = snap.currentQScoreB
    }
    
    func addDirectScore(points: Int, team: String) {
        pushUndo()
        if team == "A" { scoreA += points; currentQScoreA += points }
        else { scoreB += points; currentQScoreB += points }
    }
    
    func add2pt(playerIndex: Int, team: String) {
        pushUndo()
        if team == "A" {
            teamAPlayers[playerIndex].points2 += 1; scoreA += 2; currentQScoreA += 2
        } else {
            teamBPlayers[playerIndex].points2 += 1; scoreB += 2; currentQScoreB += 2
        }
    }
    
    func add3pt(playerIndex: Int, team: String) {
        pushUndo()
        if team == "A" {
            teamAPlayers[playerIndex].points3 += 1; scoreA += 3; currentQScoreA += 3
        } else {
            teamBPlayers[playerIndex].points3 += 1; scoreB += 3; currentQScoreB += 3
        }
    }
    
    func addFT(playerIndex: Int, team: String, made: Bool) {
        pushUndo()
        if team == "A" {
            teamAPlayers[playerIndex].ftAttempted += 1
            if made { teamAPlayers[playerIndex].ftMade += 1; scoreA += 1; currentQScoreA += 1 }
        } else {
            teamBPlayers[playerIndex].ftAttempted += 1
            if made { teamBPlayers[playerIndex].ftMade += 1; scoreB += 1; currentQScoreB += 1 }
        }
    }
    
    func addFoul(team: String) {
        pushUndo()
        if team == "A" { teamAFouls += 1 } else { teamBFouls += 1 }
    }
    
    func useTimeout(team: String) {
        pushUndo()
        if team == "A" && teamATimeoutsLeft > 0 { teamATimeoutsLeft -= 1; pauseTimer() }
        else if team == "B" && teamBTimeoutsLeft > 0 { teamBTimeoutsLeft -= 1; pauseTimer() }
    }
    
    func saveGame(ctx: ModelContext) {
        let game = HoopGame(teamAName: teamAName, teamBName: teamBName,
                            quarters: totalQuarters, quarterMinutes: quarterMinutes)
        game.finalScoreA = scoreA; game.finalScoreB = scoreB
        var allScoresA = quarterScoresA; allScoresA.append(currentQScoreA)
        var allScoresB = quarterScoresB; allScoresB.append(currentQScoreB)
        game.encodeScores(a: allScoresA, b: allScoresB)
        for p in teamAPlayers {
            let hp = HoopPlayer(name: p.name, number: p.number, team: "A")
            hp.points2 = p.points2; hp.points3 = p.points3
            hp.freeThrowsMade = p.ftMade; hp.freeThrowsAttempted = p.ftAttempted
            hp.fouls = p.fouls; hp.game = game
            game.players.append(hp)
        }
        for p in teamBPlayers {
            let hp = HoopPlayer(name: p.name, number: p.number, team: "B")
            hp.points2 = p.points2; hp.points3 = p.points3
            hp.freeThrowsMade = p.ftMade; hp.freeThrowsAttempted = p.ftAttempted
            hp.fouls = p.fouls; hp.game = game
            game.players.append(hp)
        }
        ctx.insert(game)
        try? ctx.save()
    }
}
