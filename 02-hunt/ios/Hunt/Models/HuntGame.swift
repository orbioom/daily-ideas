import Foundation
import Observation

enum HuntGamePhase: Equatable {
    case idle, playing, timeUp
}

@Observable
final class HuntGame {
    private(set) var board: [[Character]] = []
    private(set) var allWords: Set<String> = []
    private(set) var foundWords: [String] = []
    private(set) var phase: HuntGamePhase = .idle
    private(set) var timeRemaining: Int = 120
    private(set) var selectedPath: [(Int, Int)] = []
    private(set) var score: Int = 0
    private(set) var lastWord: String? = nil
    private(set) var lastWordValid: Bool = false
    private(set) var isLoadingBoard: Bool = false

    var gameDuration: Int = 120
    private var timer: Timer?

    func newGame(seed: UInt64? = nil) {
        timer?.invalidate()
        board = []
        allWords = []
        foundWords = []
        phase = .idle
        timeRemaining = gameDuration
        selectedPath = []
        score = 0
        lastWord = nil
        lastWordValid = false
        isLoadingBoard = true

        let generatedBoard = BoardGenerator.generate(seed: seed)
        Task.detached(priority: .userInitiated) {
            let words = BoardSolver.findAllWords(in: generatedBoard)
            await MainActor.run {
                self.board = generatedBoard
                self.allWords = words
                self.isLoadingBoard = false
            }
        }
    }

    func startGame() {
        guard phase == .idle, !board.isEmpty else { return }
        phase = .playing
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.phase = .timeUp
                    self.timer?.invalidate()
                }
            }
        }
    }

    func selectCell(_ r: Int, _ c: Int) {
        guard phase == .playing else { return }
        if selectedPath.isEmpty {
            selectedPath = [(r, c)]
            return
        }
        let last = selectedPath.last!
        let dr = abs(r - last.0), dc = abs(c - last.1)
        guard dr <= 1 && dc <= 1 && !(dr == 0 && dc == 0) else { return }
        guard !selectedPath.contains(where: { $0.0 == r && $0.1 == c }) else { return }
        selectedPath.append((r, c))
    }

    func commitSelection() {
        guard phase == .playing else { selectedPath = []; return }
        let word = selectedPath.map { String(board[$0.0][$0.1]) }.joined().lowercased()
        if word.count >= 3 && allWords.contains(word) && !foundWords.contains(word) {
            foundWords.append(word)
            score += scoreFor(word: word)
            lastWord = word
            lastWordValid = true
        } else if word.count >= 3 {
            lastWord = word
            lastWordValid = false
        }
        selectedPath = []
    }

    func cancelSelection() {
        selectedPath = []
    }

    var currentWord: String {
        guard !board.isEmpty else { return "" }
        return selectedPath.map { String(board[$0.0][$0.1]) }.joined()
    }

    var percentFound: Double {
        guard !allWords.isEmpty else { return 0 }
        return Double(foundWords.count) / Double(allWords.count)
    }

    private func scoreFor(word: String) -> Int {
        switch word.count {
        case 3: return 1
        case 4: return 2
        case 5: return 4
        case 6: return 7
        case 7: return 11
        default: return 16
        }
    }

    deinit { timer?.invalidate() }
}
