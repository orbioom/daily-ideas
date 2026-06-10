import Foundation
import SwiftData
import SwiftUI

@Observable
final class LexicGame {
    let game: WordGame
    private let context: ModelContext

    var current = ""             // the in-progress row
    var toast: String? = nil     // transient error/info
    var shakeRow = false
    var revealRow: Int? = nil    // row index currently flipping
    var justFinished = false

    init(game: WordGame, context: ModelContext) {
        self.game = game
        self.context = context
    }

    var guesses: [String] { game.guesses }
    var answer: String { game.answer }
    var isFinished: Bool { game.isFinished }
    var state: GameState { game.state }
    var hardMode: Bool { game.hardMode }

    func states(for guess: String) -> [LetterState] {
        WordEngine.evaluate(guess, answer: answer)
    }

    var keyboard: [Character: LetterState] {
        WordEngine.keyboardStates(guesses: guesses, answer: answer)
    }

    func type(_ letter: Character) {
        guard !isFinished, current.count < WordEngine.wordLength else { return }
        current.append(Character(letter.lowercased()))
        Haptics.selection()
    }

    func backspace() {
        guard !current.isEmpty else { return }
        current.removeLast()
        Haptics.tap()
    }

    func submit() {
        guard !isFinished else { return }
        guard current.count == WordEngine.wordLength else {
            flash("Not enough letters"); return
        }
        guard WordList.isValid(current) else {
            flash("Not in word list"); return
        }
        if hardMode, let violation = WordEngine.hardModeViolation(current, previousGuesses: guesses, answer: answer) {
            flash(violation); return
        }
        var g = game.guesses
        let row = g.count
        g.append(current)
        game.guesses = g
        revealRow = row

        if current == answer {
            game.state = .won
            game.finishedAt = .now
            finish(won: true)
        } else if g.count >= WordEngine.maxGuesses {
            game.state = .lost
            game.finishedAt = .now
            finish(won: false)
        } else {
            Haptics.tap()
        }
        current = ""
        try? context.save()
    }

    private func finish(won: Bool) {
        if won { Haptics.success() } else { Haptics.warning() }
        // Mark finished after the reveal animation completes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.justFinished = true
        }
    }

    private func flash(_ message: String) {
        toast = message
        shakeRow = true
        Haptics.warning()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.shakeRow = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            if self?.toast == message { self?.toast = nil }
        }
    }

    func shareText() -> String {
        let n = game.mode == .daily ? StatsEngine.dayNumber(for: game.startedAt) : nil
        return WordEngine.shareGrid(game, dayNumber: n)
    }
}
