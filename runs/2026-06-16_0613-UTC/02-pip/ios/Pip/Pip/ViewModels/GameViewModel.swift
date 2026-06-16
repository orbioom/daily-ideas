import SwiftUI
import Observation

/// Coordinates the GameEngine with UI concerns: roll animation gating, CPU autoplay
/// timing, toasts, and saving the finished game. Pure engine logic stays in GameEngine.
@MainActor
@Observable
final class GameViewModel {
    let engine: GameEngine
    let config: GameConfig

    /// Per-die flag toggled to trigger the tumble animation in DieView.
    var rollingDice: [Bool]
    var isAnimatingRoll = false
    var showWinner = false
    var toast: String? = nil
    var lastWasYahtzee = false
    var cpuThinking = false
    /// Suggested hold mask for the human (auto-hold hints); empty when none.
    var suggestedHolds: [Bool] = []

    private var didSaveResult = false

    init(config: GameConfig) {
        self.config = config
        self.engine = GameEngine(mode: config.mode,
                                 players: config.players,
                                 rng: SeededRNG(seed: config.seed))
        self.rollingDice = [Bool](repeating: false, count: 5)
    }

    var humanCanInteract: Bool {
        !engine.isFinished && !engine.isCurrentPlayerCPU && !isAnimatingRoll && !cpuThinking
    }

    // MARK: - Human actions

    func roll(rollDuration: Double, hapticsEnabled: Bool, reduceMotion: Bool) {
        guard engine.canRoll, !isAnimatingRoll else { return }
        let changed = engine.roll()
        Haptics.roll(enabled: hapticsEnabled)
        triggerRollAnimation(indices: changed, duration: rollDuration, reduceMotion: reduceMotion)
        refreshSuggestions()
    }

    func toggleHold(_ index: Int, hapticsEnabled: Bool) {
        guard humanCanInteract else { return }
        engine.toggleHold(index)
        Haptics.hold(enabled: hapticsEnabled)
    }

    func isHeld(_ index: Int) -> Bool {
        engine.held.indices.contains(index) ? engine.held[index] : false
    }

    func score(_ category: ScoreCategory, hapticsEnabled: Bool,
               saveAction: @escaping () -> Void) {
        guard humanCanInteract, engine.canScore else { return }
        let wasYahtzeeBonus = engine.previewAwardsYahtzeeBonus(category)
        let isYahtzeeBox = category == .yahtzee && engine.preview(category) == Scorer.yahtzeeValue
        let ok = engine.score(category)
        guard ok else { return }

        if wasYahtzeeBonus || isYahtzeeBox {
            lastWasYahtzee = true
            Haptics.yahtzee(enabled: hapticsEnabled)
            flashToast(wasYahtzeeBonus ? "Yahtzee bonus! +100" : "Yahtzee! 50")
        } else {
            Haptics.score(enabled: hapticsEnabled)
        }
        suggestedHolds = []
        afterMove(hapticsEnabled: hapticsEnabled, saveAction: saveAction)
    }

    // MARK: - Flow after any scoring move

    private func afterMove(hapticsEnabled: Bool, saveAction: @escaping () -> Void) {
        if engine.isFinished {
            finish(hapticsEnabled: hapticsEnabled, saveAction: saveAction)
        } else if engine.isCurrentPlayerCPU {
            runCPUTurn(hapticsEnabled: hapticsEnabled, saveAction: saveAction)
        }
    }

    /// Called when the game view appears, to kick off a CPU first player if needed.
    func startIfCPUFirst(hapticsEnabled: Bool, saveAction: @escaping () -> Void) {
        if engine.isCurrentPlayerCPU && !engine.isFinished {
            runCPUTurn(hapticsEnabled: hapticsEnabled, saveAction: saveAction)
        }
    }

    // MARK: - CPU autoplay

    private func runCPUTurn(hapticsEnabled: Bool, saveAction: @escaping () -> Void) {
        guard let player = engine.currentPlayer, player.isCPU else { return }
        cpuThinking = true
        let difficulty = player.cpuDifficulty ?? .sharp

        Task { @MainActor in
            // First roll.
            try? await Task.sleep(nanoseconds: 500_000_000)
            engine.roll()
            Haptics.roll(enabled: hapticsEnabled)

            // Roll up to the max, choosing holds between rolls.
            while engine.canRoll {
                try? await Task.sleep(nanoseconds: 650_000_000)
                if let p = engine.currentPlayer {
                    let holds = CPUStrategy.chooseHolds(
                        dice: engine.dice, player: p,
                        rollsRemaining: engine.rollsRemaining, difficulty: difficulty
                    )
                    engine.setHolds(holds)
                }
                try? await Task.sleep(nanoseconds: 350_000_000)
                engine.roll()
                Haptics.roll(enabled: hapticsEnabled)
            }

            try? await Task.sleep(nanoseconds: 650_000_000)
            if let p = engine.currentPlayer {
                let cat = CPUStrategy.chooseCategory(dice: engine.dice, player: p) { c in
                    engine.preview(c)
                }
                let wasBonus = engine.previewAwardsYahtzeeBonus(cat)
                engine.score(cat)
                if wasBonus { flashToast("\(p.name) hit a Yahtzee bonus!") }
            }
            cpuThinking = false
            afterMove(hapticsEnabled: hapticsEnabled, saveAction: saveAction)
        }
    }

    // MARK: - Roll animation

    private func triggerRollAnimation(indices: [Int], duration: Double, reduceMotion: Bool) {
        guard !reduceMotion, duration > 0, !indices.isEmpty else { return }
        isAnimatingRoll = true
        for i in indices where rollingDice.indices.contains(i) {
            rollingDice[i] = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) { [weak self] in
            guard let self else { return }
            for i in indices where self.rollingDice.indices.contains(i) {
                self.rollingDice[i] = false
            }
            self.isAnimatingRoll = false
        }
    }

    private func refreshSuggestions() {
        guard let player = engine.currentPlayer, !player.isCPU, engine.canRoll else {
            suggestedHolds = []
            return
        }
        suggestedHolds = CPUStrategy.chooseHolds(
            dice: engine.dice, player: player,
            rollsRemaining: engine.rollsRemaining, difficulty: .sharp
        )
    }

    // MARK: - Toast

    private func flashToast(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            if self?.toast == text { self?.toast = nil }
        }
    }

    // MARK: - Finish & persistence

    private func finish(hapticsEnabled: Bool, saveAction: @escaping () -> Void) {
        Haptics.win(enabled: hapticsEnabled)
        saveAction()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showWinner = true
        }
    }

    /// Build a GameRecord for the finished game from the human's perspective.
    func buildRecord() -> (record: GameRecord, dailyKey: String?, dailyScore: Int, dailyYahtzees: Int)? {
        guard engine.isFinished, !didSaveResult else { return nil }
        didSaveResult = true

        let human = engine.players.first { !$0.isCPU } ?? engine.players.first
        let names = engine.players.map { $0.name }
        let scores = engine.players.map { $0.grandTotal }
        let winnerName = engine.winner?.name ?? (human?.name ?? "You")
        let myScore = human?.grandTotal ?? 0
        let myYahtzees = ((human?.scores[.yahtzee] ?? 0) == Scorer.yahtzeeValue ? 1 : 0)
            + (human?.yahtzeeBonuses ?? 0)
        let didWin = (human?.name == winnerName)

        let record = GameRecord(
            date: .now,
            mode: engine.mode,
            playerNames: names,
            finalScores: scores,
            myCategoryScores: human?.scores ?? [:],
            winnerName: winnerName,
            myScore: myScore,
            myYahtzees: myYahtzees,
            didWin: didWin
        )
        return (record, config.dailyKey, myScore, myYahtzees)
    }
}
