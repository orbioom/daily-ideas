import Foundation
import SwiftUI
import SwiftData

/// Describes which game is being played, so the view model knows how to persist
/// and report results.
enum GameKind: Equatable {
    case standard(Difficulty)
    case daily(dateKey: String)
}

/// High-level phase used by the view to show overlays/loading.
enum GamePhase: Equatable {
    case generating       // no-guess board being built (async)
    case ready            // board placed and playable, or awaiting first tap
    case won
    case lost
}

/// Orchestrates a single game session: owns the `MineEngine`, drives the timer,
/// applies taps/flags/chords, persists the in-progress game, and writes results.
@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var engine: MineEngine
    @Published private(set) var phase: GamePhase = .ready
    @Published private(set) var elapsed: Double = 0
    @Published var flagMode: Bool = false

    let kind: GameKind
    let config: BoardConfig
    let noGuessRequested: Bool

    /// True if a no-guess board was requested but generation fell back to a plain
    /// board (so the UI can be honest about it).
    @Published private(set) var noGuessFellBack = false

    private var firstClickDone = false
    private var timer: Timer?
    private var seedRNG: SplitMix64
    private let savedGameID: UUID

    // Whether question-mark cycling is enabled (from settings, set by the view).
    var allowQuestionMarks = false

    var rows: Int { engine.rows }
    var cols: Int { engine.cols }

    var minesRemainingDisplay: Int { max(0, engine.minesRemaining) }
    var isOver: Bool { engine.isOver }
    var didWin: Bool { engine.didWin }

    var difficulty: Difficulty {
        switch kind {
        case .standard(let d): return d
        case .daily: return .intermediate
        }
    }

    var difficultyRaw: String {
        switch kind {
        case .standard(let d): return d.rawValue
        case .daily: return "daily"
        }
    }

    // MARK: - Init

    /// Start a brand-new game.
    init(kind: GameKind, config: BoardConfig, noGuess: Bool, seed: UInt64? = nil) {
        self.kind = kind
        self.config = config
        self.noGuessRequested = noGuess
        self.savedGameID = UUID()
        if let seed {
            self.seedRNG = SplitMix64(seed: seed)
        } else {
            self.seedRNG = SplitMix64(seed: UInt64.random(in: UInt64.min...UInt64.max))
        }
        self.engine = MineEngine(rows: config.rows, cols: config.cols,
                                 mines: config.mines, noGuess: noGuess)
        self.phase = .ready
    }

    /// Resume from a persisted game.
    init?(resuming saved: SavedGame) {
        guard let engine = saved.decodedEngine() else { return nil }
        self.kind = .standard(saved.difficulty)
        self.config = BoardConfig(rows: saved.rows, cols: saved.cols, mines: saved.mines)
        self.noGuessRequested = saved.noGuess
        self.savedGameID = saved.id
        self.seedRNG = SplitMix64(seed: UInt64.random(in: UInt64.min...UInt64.max))
        self.engine = engine
        self.firstClickDone = saved.firstClickDone
        self.elapsed = saved.elapsedSec
        if engine.isOver {
            self.phase = engine.didWin ? .won : .lost
        } else {
            self.phase = .ready
        }
    }

    // MARK: - Cell access for the view

    func cell(_ row: Int, _ col: Int) -> Cell {
        engine.cell(at: row, col) ?? Cell()
    }

    // MARK: - Timer

    /// Called when the board appears so a resumed, in-progress game keeps ticking.
    func resumeTimerIfNeeded() {
        startTimerIfNeeded()
    }

    func startTimerIfNeeded() {
        guard firstClickDone, !engine.isOver, timer == nil else { return }
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !engine.isOver else { stopTimer(); return }
        elapsed += 1
    }

    // MARK: - Input

    /// Handle a primary tap on a cell. Honors flag-mode.
    func primaryTap(row: Int, col: Int, haptics: Bool) {
        guard !engine.isOver else { return }
        let i = engine.index(row, col)
        let current = engine.cell(at: row, col) ?? Cell()

        if flagMode {
            toggleFlag(row: row, col: col, haptics: haptics)
            return
        }

        // Chording: tapping an already-revealed number.
        if current.state == .revealed && current.adjacent > 0 {
            let outcome = engine.chord(i)
            if haptics { Haptics.tap() }
            resolve(outcome, haptics: haptics)
            persist()
            return
        }

        // Flagged cells are protected from accidental reveal.
        if current.state == .flagged { return }

        ensureFirstClick(at: i)
        let outcome = engine.reveal(i)
        if haptics && outcome == .ok { Haptics.tap() }
        startTimerIfNeeded()
        resolve(outcome, haptics: haptics)
        persist()
    }

    /// Long-press (or flag-mode) toggle.
    func toggleFlag(row: Int, col: Int, haptics: Bool) {
        guard !engine.isOver else { return }
        let i = engine.index(row, col)
        let current = engine.cell(at: row, col) ?? Cell()
        guard current.state != .revealed else {
            // Long-press on a number also chords (a common convenience).
            if current.adjacent > 0 {
                let outcome = engine.chord(i)
                resolve(outcome, haptics: haptics)
                persist()
            }
            return
        }
        engine.cycleFlag(i, allowQuestion: allowQuestionMarks)
        if haptics { Haptics.flag() }
        objectWillChange.send()
        persist()
    }

    private func ensureFirstClick(at i: Int) {
        guard !firstClickDone else { return }
        firstClickDone = true
        if noGuessRequested {
            generateNoGuess(firstTap: i)
        } else {
            engine.placeMines(firstTap: i, using: &seedRNG)
        }
    }

    private func generateNoGuess(firstTap i: Int) {
        if let layout = Solver.generateNoGuess(rows: config.rows,
                                               cols: config.cols,
                                               mines: config.mines,
                                               firstTap: i,
                                               rng: &seedRNG,
                                               maxAttempts: 200) {
            engine.setMineLayout(layout)
            noGuessFellBack = false
        } else {
            // Couldn't build a solvable board within the attempt cap; fall back to
            // a normal first-click-safe board and tell the player.
            engine.placeMines(firstTap: i, using: &seedRNG)
            noGuessFellBack = true
        }
    }

    private func resolve(_ outcome: MoveOutcome, haptics: Bool) {
        switch outcome {
        case .ok:
            objectWillChange.send()
        case .won:
            phase = .won
            stopTimer()
            if haptics { Haptics.win() }
        case .lost:
            phase = .lost
            stopTimer()
            if haptics { Haptics.lose() }
        }
    }

    // MARK: - Persistence

    private weak var context: ModelContext?

    func bind(context: ModelContext) {
        self.context = context
    }

    /// Save (or clear) the in-progress game. Finished games are deleted so the
    /// Home "Resume" card disappears.
    func persist() {
        guard let context else { return }
        if engine.isOver {
            deleteSaved()
            return
        }
        // Daily games are not resumable across launches (kept simple & honest:
        // standard games persist; daily is a fresh sit-down each time).
        if case .daily = kind { return }

        guard let data = try? JSONEncoder().encode(engine),
              let json = String(data: data, encoding: .utf8) else { return }

        // Single in-progress game: replace any existing saved game.
        let descriptor = FetchDescriptor<SavedGame>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for game in existing { context.delete(game) }

        let saved = SavedGame(id: savedGameID,
                              difficultyRaw: difficultyRaw == "daily" ? Difficulty.intermediate.rawValue : difficultyRaw,
                              rows: config.rows,
                              cols: config.cols,
                              mines: config.mines,
                              elapsedSec: elapsed,
                              boardJSON: json,
                              firstClickDone: firstClickDone,
                              noGuess: noGuessRequested)
        context.insert(saved)
        try? context.save()
    }

    private func deleteSaved() {
        guard let context else { return }
        let descriptor = FetchDescriptor<SavedGame>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for game in existing { context.delete(game) }
        try? context.save()
    }

    /// Write the final result (GameRecord, and DailyResult for daily games).
    /// Returns true if a record was written (idempotent guard prevents doubles).
    private var recordedResult = false
    func recordResultIfNeeded() {
        guard engine.isOver, !recordedResult, let context else { return }
        recordedResult = true

        let record = GameRecord(difficultyRaw: difficultyRaw,
                                rows: config.rows,
                                cols: config.cols,
                                mines: config.mines,
                                won: engine.didWin,
                                durationSec: elapsed,
                                noGuess: noGuessRequested && !noGuessFellBack)
        context.insert(record)

        if case .daily(let dateKey) = kind {
            // Upsert: keep the player's existing daily result if it exists.
            let descriptor = FetchDescriptor<DailyResult>(
                predicate: #Predicate { $0.dateKey == dateKey }
            )
            let existing = (try? context.fetch(descriptor)) ?? []
            if existing.isEmpty {
                context.insert(DailyResult(dateKey: dateKey,
                                           won: engine.didWin,
                                           durationSec: elapsed))
            }
        }
        try? context.save()
    }
}
