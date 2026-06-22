import Foundation
import PencilKit
import UIKit

struct ScrawlTeam: Identifiable, Equatable {
    let id: UUID
    var name: String
    var score: Int

    init(id: UUID = UUID(), name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}

@Observable
class ScrawlGameEngine {
    // MARK: - Game State
    var teams: [ScrawlTeam] = []
    var currentTeamIndex: Int = 0
    var currentWord: String = ""
    var currentWordPack: String = "Animals"
    var roundsRemaining: Int = 3
    var totalRounds: Int = 3
    var timerSeconds: Int = 60
    var timeRemaining: Int = 60
    var phase: GamePhase = .setup
    var drawing: PKDrawing = PKDrawing()
    var guessText: String = ""
    var isCorrect: Bool = false
    var usedWords: Set<String> = []
    var showTimerWarning: Bool = false

    // MARK: - Private
    private var timer: Timer?
    private var wordPool: [String] = []
    private var hapticsEnabled: Bool = true

    enum GamePhase: Equatable {
        case setup
        case wordReveal
        case drawing
        case guessing
        case result
        case gameOver
    }

    // MARK: - Setup
    func configure(
        teams: [ScrawlTeam],
        wordPack: String,
        words: [String],
        rounds: Int,
        timerSeconds: Int,
        hapticsEnabled: Bool
    ) {
        self.teams = teams
        self.currentWordPack = wordPack
        self.wordPool = words.shuffled()
        self.totalRounds = rounds
        self.roundsRemaining = rounds
        self.timerSeconds = timerSeconds
        self.timeRemaining = timerSeconds
        self.hapticsEnabled = hapticsEnabled
        self.currentTeamIndex = 0
        self.usedWords = []
        self.phase = .wordReveal
        self.drawing = PKDrawing()
        self.guessText = ""
        pickNextWord()
    }

    // MARK: - Word Management
    private func pickNextWord() {
        let available = wordPool.filter { !usedWords.contains($0) }
        if let word = available.randomElement() {
            currentWord = word
            usedWords.insert(word)
        } else {
            // Reshuffle if exhausted
            usedWords.removeAll()
            currentWord = wordPool.randomElement() ?? "elephant"
            usedWords.insert(currentWord)
        }
    }

    // MARK: - Phase Transitions
    func artistIsReady() {
        guard phase == .wordReveal else { return }
        phase = .drawing
        drawing = PKDrawing()
        startTimer()
    }

    func passToGuesser() {
        stopTimer()
        phase = .guessing
        guessText = ""
    }

    func submitGuess() {
        let normalized = guessText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let target = currentWord.lowercased()
        isCorrect = normalized == target || normalized.contains(target) || target.contains(normalized)

        if isCorrect {
            teams[currentTeamIndex].score += 1
            fireHaptic(type: .success)
        } else {
            fireHaptic(type: .failure)
        }
        phase = .result
    }

    func advanceTurn() {
        if roundsRemaining <= 1 && currentTeamIndex >= teams.count - 1 {
            roundsRemaining = 0
            phase = .gameOver
            return
        }

        currentTeamIndex = (currentTeamIndex + 1) % teams.count
        if currentTeamIndex == 0 {
            roundsRemaining -= 1
        }

        drawing = PKDrawing()
        guessText = ""
        pickNextWord()
        timeRemaining = timerSeconds
        showTimerWarning = false
        phase = .wordReveal
    }

    func skipWord() {
        stopTimer()
        isCorrect = false
        phase = .result
        fireHaptic(type: .failure)
    }

    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        timeRemaining = timerSeconds
        showTimerWarning = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.tickTimer()
        }
    }

    private func tickTimer() {
        guard timeRemaining > 0 else {
            stopTimer()
            timeRemaining = 0
            passToGuesser()
            return
        }
        timeRemaining -= 1

        if timeRemaining <= 10 && !showTimerWarning {
            showTimerWarning = true
            fireHaptic(type: .warning)
        } else if timeRemaining <= 10 && timeRemaining > 0 {
            fireHaptic(type: .tick)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func pauseForBackground() {
        stopTimer()
    }

    func resumeFromBackground() {
        if phase == .drawing && timeRemaining > 0 {
            startTimer()
        }
    }

    // MARK: - Haptics
    private enum HapticType {
        case success, failure, warning, tick
    }

    private func fireHaptic(type: HapticType) {
        guard hapticsEnabled else { return }
        switch type {
        case .success:
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        case .failure:
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
        case .warning:
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
        case .tick:
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }
    }

    // MARK: - Computed Properties
    var currentTeam: ScrawlTeam? {
        guard teams.indices.contains(currentTeamIndex) else { return nil }
        return teams[currentTeamIndex]
    }

    var timerProgress: Double {
        guard timerSeconds > 0 else { return 0 }
        return Double(timeRemaining) / Double(timerSeconds)
    }

    var winnerTeam: ScrawlTeam? {
        teams.max(by: { $0.score < $1.score })
    }

    var isTied: Bool {
        guard let maxScore = teams.map(\.score).max() else { return false }
        return teams.filter { $0.score == maxScore }.count > 1
    }

    func resetGame() {
        stopTimer()
        teams = []
        currentTeamIndex = 0
        currentWord = ""
        roundsRemaining = 0
        totalRounds = 0
        timeRemaining = 60
        phase = .setup
        drawing = PKDrawing()
        guessText = ""
        usedWords = []
        showTimerWarning = false
    }
}
