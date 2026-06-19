import Foundation
import SwiftData

enum PuzzleState: Equatable {
    case playing, solved, failed
}

@Observable
class MuddleEngine {
    var scrambledLetters: [String] = []
    var selectedIndices: [Int] = []
    var state: PuzzleState = .playing
    var hintsUsed: Int = 0
    var timeElapsed: TimeInterval = 0
    var hintsRevealed: [Bool] = []

    private var entry: WordEntry?
    private var timer: Timer?

    var targetWord: String { entry?.word ?? "" }
    var hint: String { entry?.hint ?? "" }
    var category: WordCategory? { entry?.category }

    var currentGuess: String {
        selectedIndices.map { scrambledLetters[$0] }.joined()
    }

    var isCorrect: Bool { currentGuess == targetWord }

    func load(entry: WordEntry) {
        self.entry = entry
        scramble(word: entry.word)
        hintsRevealed = Array(repeating: false, count: entry.word.count)
        state = .playing
        hintsUsed = 0
        timeElapsed = 0
        selectedIndices = []
        startTimer()
    }

    private func scramble(word: String) {
        var letters = word.map { String($0) }
        repeat {
            letters.shuffle()
        } while letters.joined() == word && word.count > 1
        scrambledLetters = letters
    }

    func tap(index: Int) {
        guard state == .playing else { return }
        if selectedIndices.contains(index) {
            selectedIndices.removeAll { $0 == index }
        } else {
            selectedIndices.append(index)
            if currentGuess == targetWord {
                state = .solved
                stopTimer()
            }
        }
    }

    func clear() {
        selectedIndices = []
    }

    func shuffle() {
        let selected = selectedIndices.map { scrambledLetters[$0] }
        var unselected = scrambledLetters.enumerated()
            .filter { !selectedIndices.contains($0.offset) }
            .map { $0.element }
        unselected.shuffle()
        var newLetters = Array(repeating: "", count: scrambledLetters.count)
        var ui = 0; var si = 0
        for i in 0..<newLetters.count {
            if selectedIndices.contains(i) {
                newLetters[i] = selected[si]; si += 1
            } else {
                newLetters[i] = unselected[ui]; ui += 1
            }
        }
        scrambledLetters = newLetters
    }

    func useHint() -> Bool {
        guard hintsUsed < targetWord.count else { return false }
        hintsRevealed[hintsUsed] = true
        hintsUsed += 1
        return true
    }

    var revealedPrefix: String {
        hintsRevealed.enumerated()
            .filter { $0.element }
            .map { String(targetWord[$0.offset]) }
            .joined()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.timeElapsed += 1
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    func timeString() -> String {
        let m = Int(timeElapsed) / 60; let s = Int(timeElapsed) % 60
        return String(format: "%d:%02d", m, s)
    }
}

extension String {
    subscript(i: Int) -> Character {
        self[index(startIndex, offsetBy: i)]
    }
}
