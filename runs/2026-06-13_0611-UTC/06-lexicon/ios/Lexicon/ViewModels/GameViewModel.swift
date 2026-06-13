import Foundation
import SwiftUI

@MainActor
@Observable
final class GameViewModel {
    let answer: String
    let dayKey: String          // "" for practice
    let hardMode: Bool
    let persistProgress: Bool

    var guesses: [String] = []
    var rows: [[LetterState]] = []
    var current: String = ""
    var status: Status = .playing
    var message: String?
    var shakeRow = 0            // increments to trigger a shake on the current row

    /// Called exactly once when the game ends because of a submit.
    var onComplete: ((_ won: Bool, _ guesses: [String]) -> Void)?

    enum Status { case playing, won, lost }

    init(answer: String, dayKey: String, hardMode: Bool, persistProgress: Bool) {
        self.answer = answer.lowercased()
        self.dayKey = dayKey
        self.hardMode = hardMode
        self.persistProgress = persistProgress
        if persistProgress { loadProgress() }
    }

    var keyboardStates: [Character: LetterState] {
        WordGame.keyboardStates(rows: rows, guesses: guesses)
    }

    var rowsRemaining: Int { WordGame.maxRows - guesses.count }

    // MARK: input

    func type(_ letter: Character) {
        guard status == .playing, current.count < WordGame.wordLength else { return }
        current.append(Character(letter.lowercased()))
    }

    func backspace() {
        guard status == .playing, !current.isEmpty else { return }
        current.removeLast()
    }

    func submit() {
        guard status == .playing else { return }
        guard current.count == WordGame.wordLength else {
            flash("Not enough letters"); return
        }
        guard WordList.isValid(current) else {
            flash("Not in word list"); return
        }
        if hardMode, let violation = hardModeViolation() {
            flash(violation); return
        }

        let guess = current
        let states = WordGame.evaluate(guess: guess, answer: answer)
        guesses.append(guess)
        rows.append(states)
        current = ""
        message = nil

        if guess == answer {
            status = .won
            finish(won: true)
        } else if guesses.count >= WordGame.maxRows {
            status = .lost
            finish(won: false)
        }
        saveProgress()
    }

    private func finish(won: Bool) {
        saveProgress()
        onComplete?(won, guesses)
    }

    private func flash(_ text: String) {
        message = text
        shakeRow += 1
        Haptics.warning()
    }

    // MARK: hard mode

    private func hardModeViolation() -> String? {
        let cur = Array(current)
        for (gi, guess) in guesses.enumerated() {
            let g = Array(guess)
            for (i, st) in rows[gi].enumerated() {
                if st == .correct, cur[i] != g[i] {
                    return "Spot \(i + 1) must be \(String(g[i]).uppercased())"
                }
            }
            for (i, st) in rows[gi].enumerated() where st == .present {
                if !cur.contains(g[i]) {
                    return "Guess must contain \(String(g[i]).uppercased())"
                }
            }
        }
        return nil
    }

    // MARK: progress persistence (daily / archive resume)

    private var progressKey: String { "lex.progress.\(dayKey)" }

    private func saveProgress() {
        guard persistProgress, !dayKey.isEmpty else { return }
        if let data = try? JSONEncoder().encode(guesses) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() {
        guard !dayKey.isEmpty,
              let data = UserDefaults.standard.data(forKey: progressKey),
              let saved = try? JSONDecoder().decode([String].self, from: data) else { return }
        for guess in saved {
            guesses.append(guess)
            rows.append(WordGame.evaluate(guess: guess, answer: answer))
            if guess == answer { status = .won }
        }
        if status != .won, guesses.count >= WordGame.maxRows { status = .lost }
    }
}
