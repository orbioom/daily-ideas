import SwiftUI
import SwiftData

/// Drives a single board: typing, submitting, evaluating, persistence, hard-mode
/// validation, keyboard aggregation and share-string building.
///
/// Uses the Observation framework (`@Observable`) and is stored with `@State` in the
/// owning view (never `@StateObject`).
@Observable
final class GameViewModel {

    // MARK: - Configuration

    let mode: GameMode
    let wordLength: Int
    let answer: String          // lowercased
    let puzzleDate: Date        // start of day for daily/archive; .now for practice
    let savedKey: String
    let maxGuesses = DailyPuzzle.maxGuesses

    // MARK: - Board state

    /// Per-row typed letters (uppercase). A row has 0...wordLength entries.
    private(set) var rows: [[Character]]
    /// Per-row evaluated states. Only rows < currentRow are populated.
    private(set) var states: [[TileState]]
    private(set) var currentRow: Int = 0
    private(set) var status: GameStatus = .playing

    /// A transient, calm message (invalid word / hard-mode violation). Auto-clears.
    private(set) var message: String?
    /// Bumped each time the current row should "shake" (invalid entry).
    private(set) var shakeToken: Int = 0
    /// The row index that was most recently submitted (for flip animation), or nil.
    private(set) var lastSubmittedRow: Int?

    // MARK: - Init

    init(mode: GameMode, wordLength: Int, answer: String, puzzleDate: Date, savedKey: String) {
        self.mode = mode
        self.wordLength = max(1, wordLength)
        self.answer = answer.lowercased()
        self.puzzleDate = puzzleDate
        self.savedKey = savedKey
        self.rows = Array(repeating: [], count: maxGuesses)
        self.states = Array(repeating: [], count: maxGuesses)
    }

    // MARK: - Derived

    var isFinished: Bool { status.isFinished }
    var didWin: Bool { status == .won }

    /// The guesses already submitted, as lowercase strings.
    var submittedGuesses: [String] {
        guard currentRow > 0 else { return [] }
        return (0..<currentRow).compactMap { r in
            guard let row = rows[safe: r] else { return nil }
            return String(row).lowercased()
        }
    }

    /// 1...maxGuesses on a win (the winning row number); maxGuesses on a loss.
    var guessCountForResult: Int {
        status == .won ? currentRow : maxGuesses
    }

    // MARK: - Typing

    func typeLetter(_ letter: Character) {
        guard !isFinished else { return }
        guard let row = rows[safe: currentRow], row.count < wordLength else { return }
        rows[currentRow].append(Character(String(letter).uppercased()))
        clearMessage()
    }

    func deleteLetter() {
        guard !isFinished else { return }
        guard var row = rows[safe: currentRow], !row.isEmpty else { return }
        row.removeLast()
        rows[currentRow] = row
        clearMessage()
    }

    // MARK: - Submit

    /// Attempts to submit the current row. Returns the evaluated states on success,
    /// or nil if rejected (too short / invalid word / hard-mode violation). On a
    /// rejection a calm `message` is set and `shakeToken` is bumped.
    @discardableResult
    func submit(hardMode: Bool) -> [TileState]? {
        guard !isFinished else { return nil }
        guard let row = rows[safe: currentRow] else { return nil }

        guard row.count == wordLength else {
            reject("Not enough letters")
            return nil
        }

        let guess = String(row).lowercased()

        guard WordLists.isValidGuess(guess, length: wordLength) else {
            reject("Not in word list")
            return nil
        }

        if hardMode, let violation = hardModeViolation(for: guess) {
            reject(violation)
            return nil
        }

        let evaluated = GuessEvaluator.evaluate(guess: guess, answer: answer)
        states[currentRow] = evaluated
        lastSubmittedRow = currentRow

        if guess == answer {
            status = .won
        } else if currentRow + 1 >= maxGuesses {
            status = .lost
        }
        currentRow += 1
        clearMessage()
        return evaluated
    }

    private func reject(_ text: String) {
        message = text
        shakeToken += 1
    }

    private func clearMessage() {
        if message != nil { message = nil }
    }

    func dismissMessage() { message = nil }

    // MARK: - Hard mode

    /// Returns a human-readable violation string if `guess` breaks hard-mode rules,
    /// else nil. Rules: every revealed green must stay in its position, and every
    /// revealed yellow letter must be reused somewhere in the guess.
    func hardModeViolation(for guess: String) -> String? {
        let g = Array(guess.lowercased())
        guard currentRow > 0 else { return nil }

        // Greens: any position revealed correct must match.
        for r in 0..<currentRow {
            guard let rowStates = states[safe: r], let rowLetters = rows[safe: r] else { continue }
            for i in rowStates.indices where rowStates[i] == .correct {
                guard let letter = rowLetters[safe: i] else { continue }
                let requiredChar = Character(String(letter).lowercased())
                if g[safe: i] != requiredChar {
                    let pos = i + 1
                    return "Position \(pos) must be \(String(requiredChar).uppercased())"
                }
            }
        }

        // Yellows: every letter revealed present must appear in the guess.
        var requiredPresent: Set<Character> = []
        for r in 0..<currentRow {
            guard let rowStates = states[safe: r], let rowLetters = rows[safe: r] else { continue }
            for i in rowStates.indices where rowStates[i] == .present {
                if let c = rowLetters[safe: i] {
                    requiredPresent.insert(Character(String(c).lowercased()))
                }
            }
        }
        for c in requiredPresent where !g.contains(c) {
            return "Guess must contain \(String(c).uppercased())"
        }

        return nil
    }

    // MARK: - Keyboard aggregation

    /// Best-known state per letter across all submitted rows (green > yellow > gray).
    func keyboardStates() -> [Character: TileState] {
        var best: [Character: TileState] = [:]
        for r in 0..<currentRow {
            guard let rowStates = states[safe: r], let rowLetters = rows[safe: r] else { continue }
            for i in rowLetters.indices {
                let ch = Character(String(rowLetters[i]).lowercased())
                let st = rowStates[safe: i] ?? .absent
                let current = best[ch]
                if current == nil || st.keyboardRank > (current?.keyboardRank ?? 0) {
                    best[ch] = st
                }
            }
        }
        return best
    }

    // MARK: - Snapshot / restore

    func makeSnapshot() -> BoardSnapshot {
        let letters = rows.map { row in row.map { String($0) } }
        let stateInts = states.map { row in row.map { $0.rawValue } }
        return BoardSnapshot(letters: letters, states: stateInts)
    }

    /// Rebuild board state from a saved snapshot. Tolerant of malformed data.
    func restore(from snapshot: BoardSnapshot, status: GameStatus, currentRow: Int) {
        var newRows: [[Character]] = Array(repeating: [], count: maxGuesses)
        var newStates: [[TileState]] = Array(repeating: [], count: maxGuesses)
        for r in 0..<maxGuesses {
            if let letterRow = snapshot.letters[safe: r] {
                newRows[r] = letterRow.compactMap { $0.uppercased().first }
            }
            if let stateRow = snapshot.states[safe: r] {
                newStates[r] = stateRow.map { TileState(rawValue: $0) ?? .absent }
            }
        }
        self.rows = newRows
        self.states = newStates
        self.currentRow = min(max(0, currentRow), maxGuesses)
        self.status = status
    }

    // MARK: - Persistence

    /// Persist the current board (or clear it if there's nothing useful to resume).
    func persist(in context: ModelContext) {
        // Nothing started and not finished → don't litter the store.
        if currentRow == 0 && status == .playing && (rows[safe: 0]?.isEmpty ?? true) {
            SavedGameStore.clear(key: savedKey, in: context)
            return
        }
        guard let json = SavedGameStore.encode(makeSnapshot()) else { return }
        if let existing = SavedGameStore.fetch(key: savedKey, in: context) {
            existing.gridJSON = json
            existing.currentRow = currentRow
            existing.statusRaw = status.rawValue
            existing.modeRaw = mode.rawValue
            existing.answer = answer
            existing.wordLength = wordLength
            existing.puzzleDate = puzzleDate
            existing.updatedAt = .now
        } else {
            let saved = SavedGame(
                key: savedKey,
                wordLength: wordLength,
                answer: answer,
                gridJSON: json,
                currentRow: currentRow,
                status: status,
                mode: mode,
                puzzleDate: puzzleDate
            )
            context.insert(saved)
        }
        try? context.save()
    }

    /// Record a finished game into the stats store exactly once.
    func recordResultIfNeeded(in context: ModelContext) {
        guard isFinished else { return }
        // De-dupe: for daily/archive, avoid double-recording the same puzzle.
        if mode != .practice {
            let descriptor = FetchDescriptor<GameResult>()
            let existing = (try? context.fetch(descriptor)) ?? []
            let stamp = DailyPuzzle.dateStamp(for: puzzleDate)
            let already = existing.contains { r in
                r.gameMode == mode && r.wordLength == wordLength &&
                DailyPuzzle.dateStamp(for: r.date) == stamp
            }
            if already { return }
        }
        let result = GameResult(
            date: mode == .practice ? .now : puzzleDate,
            word: answer,
            mode: mode,
            wordLength: wordLength,
            guessCount: guessCountForResult,
            won: didWin
        )
        context.insert(result)
        try? context.save()
    }

    // MARK: - Share

    /// Builds the emoji-grid share string for the finished board.
    func shareText(highContrast: Bool) -> String {
        let header: String
        switch mode {
        case .daily:
            header = "Lexicon \(DailyPuzzle.dateStamp(for: puzzleDate))"
        case .archive:
            header = "Lexicon Archive \(DailyPuzzle.dateStamp(for: puzzleDate))"
        case .practice:
            header = "Lexicon Practice"
        }
        let score = didWin ? "\(guessCountForResult)/\(maxGuesses)" : "X/\(maxGuesses)"
        var lines = ["\(header) \(score)", ""]
        for r in 0..<currentRow {
            guard let rowStates = states[safe: r], !rowStates.isEmpty else { continue }
            let line = rowStates.map { emoji(for: $0, highContrast: highContrast) }.joined()
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    private func emoji(for state: TileState, highContrast: Bool) -> String {
        switch state {
        case .correct: return highContrast ? "🟧" : "🟩"
        case .present: return highContrast ? "🟦" : "🟨"
        default:       return "⬛"
        }
    }
}
