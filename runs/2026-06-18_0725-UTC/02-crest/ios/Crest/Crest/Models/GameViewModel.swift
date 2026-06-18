import SwiftUI
import SwiftData
import Observation

/// View-model wrapping the pure engine, owning UI/session concerns: wall-clock
/// timing anchored to scenePhase, persistence of the saved game, and recording
/// a GameResult on finish.
@Observable
@MainActor
final class GameViewModel {
    private(set) var engine: CrestEngine
    private(set) var outcome: GameOutcome = .playing

    /// Transient hint highlight (position index) — cleared after a moment.
    var hintedPosition: Int?
    /// The last position cleared, for a brief clear animation pulse.
    var lastClearedPosition: Int?
    /// Set true once the finishing result has been written, to avoid double-recording.
    private(set) var recorded = false

    // Timing
    private(set) var startDate: Date          // anchor for the live clock
    private var accumulated: Double           // seconds banked before current anchor
    private(set) var isRunning = true

    let layout: BoardLayout
    let dealNumber: Int
    let isDaily: Bool

    init(layout: BoardLayout, dealNumber: Int, isDaily: Bool, wrap: Bool) {
        self.engine = CrestEngine(layout: layout, dealNumber: dealNumber, isDaily: isDaily, wrap: wrap)
        self.layout = layout
        self.dealNumber = dealNumber
        self.isDaily = isDaily
        self.startDate = Date()
        self.accumulated = 0
        self.outcome = engine.outcome
    }

    /// Resume from a persisted state.
    init(resuming state: BoardState, startedAt: Date, elapsedAccum: Double, wrap: Bool) {
        self.engine = CrestEngine(state: state, wrap: wrap)
        self.layout = state.layout
        self.dealNumber = state.dealNumber
        self.isDaily = state.isDaily
        self.startDate = Date()
        self.accumulated = max(0, elapsedAccum)
        self.outcome = engine.outcome
        if self.outcome != .playing { self.isRunning = false }
    }

    // MARK: - Derived view data

    var state: BoardState { engine.state }
    var score: Int { engine.state.score }
    var combo: Int { engine.state.combo }
    var longestCombo: Int { engine.state.longestCombo }
    var cardsCleared: Int { engine.state.cardsCleared }
    var stockCount: Int { engine.state.stock.count }
    var topWaste: Card? { engine.state.topWaste }
    var canUndo: Bool { engine.canUndo }
    var canDraw: Bool { stockCount > 0 && outcome == .playing }

    func isPlayable(_ i: Int) -> Bool { engine.isPlayable(i) }
    func card(at i: Int) -> Card? {
        guard i >= 0, i < engine.state.tableau.count else { return nil }
        return engine.state.tableau[i]
    }
    func isLegalNow(_ i: Int) -> Bool {
        guard isPlayable(i), let c = card(at: i) else { return false }
        return engine.playable(card: c, onWaste: topWaste)
    }

    /// Live elapsed seconds at a given reference moment.
    func elapsed(at now: Date) -> Double {
        guard isRunning else { return accumulated }
        return accumulated + max(0, now.timeIntervalSince(startDate))
    }

    // MARK: - Timer anchoring (scenePhase)

    /// Call when the app becomes active: re-anchor the clock to "now".
    func resumeClock() {
        guard outcome == .playing else { return }
        startDate = Date()
        isRunning = true
    }

    /// Call when the app resigns active: bank elapsed time into `accumulated`.
    func pauseClock() {
        guard isRunning else { return }
        accumulated = elapsed(at: Date())
        isRunning = false
    }

    private func stopClock() {
        accumulated = elapsed(at: Date())
        isRunning = false
    }

    // MARK: - Actions

    @discardableResult
    func play(_ i: Int, settings: AppSettings) -> Bool {
        guard outcome == .playing else { return false }
        let didPlay = engine.play(i)
        if didPlay {
            lastClearedPosition = i
            hintedPosition = nil
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            SoundPlayer.draw(enabled: settings.drawSound)
            refreshOutcome(settings: settings)
        } else {
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
        }
        return didPlay
    }

    @discardableResult
    func draw(settings: AppSettings) -> Bool {
        guard outcome == .playing else { return false }
        let didDraw = engine.drawFromStock()
        if didDraw {
            hintedPosition = nil
            Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
            SoundPlayer.draw(enabled: settings.drawSound)
            refreshOutcome(settings: settings)
        }
        return didDraw
    }

    func undo(settings: AppSettings) {
        guard engine.undo() else { return }
        hintedPosition = nil
        outcome = engine.outcome
        if outcome == .playing { isRunning = true }
        Haptics.impact(.soft, enabled: settings.hapticsEnabled)
    }

    func requestHint(settings: AppSettings) {
        if let move = engine.hint() {
            hintedPosition = move
            Haptics.selection(enabled: settings.hapticsEnabled)
        } else {
            hintedPosition = nil
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
        }
    }

    func clearHint() { hintedPosition = nil }

    private func refreshOutcome(settings: AppSettings) {
        let new = engine.outcome
        outcome = new
        if new != .playing {
            stopClock()
            if new == .won {
                Haptics.notify(.success, enabled: settings.hapticsEnabled)
                SoundPlayer.win(enabled: settings.drawSound)
            } else {
                Haptics.notify(.error, enabled: settings.hapticsEnabled)
            }
        }
    }

    // MARK: - Persistence

    /// Encode current board for the SavedGame row.
    func encodedBoard() -> Data? {
        var snapshot = engine.state
        snapshot.elapsedAccum = elapsed(at: Date())
        return try? JSONEncoder().encode(snapshot)
    }

    /// Persist (or update) the single saved-game row so the game can resume.
    func persist(into context: ModelContext) {
        guard outcome == .playing else {
            // Game finished — remove any saved game so we don't resume a dead board.
            clearSaved(in: context)
            return
        }
        guard let data = encodedBoard() else { return }
        let now = elapsed(at: Date())
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.slot == 0 })
        if let existing = try? context.fetch(descriptor), let row = existing.first {
            row.boardData = data
            row.layoutRaw = layout.rawValue
            row.dealNumber = dealNumber
            row.isDaily = isDaily
            row.elapsedAccum = now
        } else {
            let row = SavedGame(
                boardData: data,
                layoutRaw: layout.rawValue,
                dealNumber: dealNumber,
                isDaily: isDaily,
                startedAt: Date().addingTimeInterval(-now),
                elapsedAccum: now
            )
            context.insert(row)
        }
        try? context.save()
    }

    func clearSaved(in context: ModelContext) {
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.slot == 0 })
        if let rows = try? context.fetch(descriptor) {
            for r in rows { context.delete(r) }
            try? context.save()
        }
    }

    /// Write a GameResult exactly once when the game ends.
    func recordResultIfNeeded(into context: ModelContext) {
        guard outcome != .playing, !recorded else { return }
        recorded = true
        let result = GameResult(
            layoutRaw: layout.rawValue,
            won: outcome == .won,
            score: score,
            durationSec: elapsed(at: Date()),
            cardsCleared: cardsCleared,
            longestCombo: longestCombo,
            dealNumber: dealNumber,
            isDaily: isDaily,
            date: Date()
        )
        context.insert(result)
        clearSaved(in: context)
        try? context.save()
    }
}
