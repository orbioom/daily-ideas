import SwiftUI
import Observation
import SwiftData
import UIKit

/// Drives a single practice block: a `Date`-based countdown that survives UI churn,
/// keeps the screen awake while running, and writes a `PracticeSession` on completion.
///
/// Timing is computed from absolute `Date`s (start instant + accumulated elapsed),
/// never by summing timer ticks, so it stays accurate across pauses and stalls.
@MainActor
@Observable
final class PracticeSessionEngine {

    enum Phase: Equatable {
        case idle       // configured, not yet started
        case running
        case paused
        case finished   // time reached zero or stopped early; ready to save
    }

    private(set) var phase: Phase = .idle

    /// Whole target length of the block in seconds (the countdown ceiling).
    private(set) var targetSeconds: Int

    /// Elapsed seconds, derived from the clock; clamped at `targetSeconds`.
    private(set) var elapsedSeconds: Int = 0

    private var startInstant: Date?
    /// Elapsed accumulated before the current run segment (across pauses).
    private var bankedElapsed: TimeInterval = 0
    private var timer: Timer?

    init(targetMinutes: Int) {
        self.targetSeconds = max(1, targetMinutes) * 60
    }

    // MARK: - Derived

    var remainingSeconds: Int { max(0, targetSeconds - elapsedSeconds) }

    /// Progress 0…1 toward the target. Guarded against a zero target.
    var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1, max(0, Double(elapsedSeconds) / Double(targetSeconds)))
    }

    var isActive: Bool { phase == .running || phase == .paused }

    /// mm:ss for the remaining countdown.
    var remainingLabel: String { Self.clock(remainingSeconds) }
    /// mm:ss for time already practiced.
    var elapsedLabel: String { Self.clock(elapsedSeconds) }

    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - Configuration

    /// Adjust the target before starting (e.g. the user dials a different length).
    func setTargetMinutes(_ minutes: Int) {
        guard phase == .idle else { return }
        targetSeconds = max(1, minutes) * 60
    }

    // MARK: - Transport

    func start() {
        guard phase == .idle || phase == .paused else { return }
        startInstant = Date()
        phase = .running
        UIApplication.shared.isIdleTimerDisabled = true
        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        t.tolerance = 0.05
        RunLoop.main.add(t, forMode: .common)
        timer = t
        refresh()
    }

    func pause() {
        guard phase == .running else { return }
        bankedElapsed = currentElapsed()
        startInstant = nil
        invalidateTimer()
        phase = .paused
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resume() { start() }

    /// Stop early; banks elapsed time and moves to `finished` so it can be saved.
    func finish() {
        bankedElapsed = currentElapsed()
        startInstant = nil
        invalidateTimer()
        elapsedSeconds = min(targetSeconds, Int(bankedElapsed.rounded()))
        phase = .finished
        UIApplication.shared.isIdleTimerDisabled = false
    }

    /// Discard the session entirely (no save) and reset transport state.
    func cancel() {
        invalidateTimer()
        startInstant = nil
        bankedElapsed = 0
        elapsedSeconds = 0
        phase = .idle
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func refresh() {
        elapsedSeconds = min(targetSeconds, Int(currentElapsed().rounded()))
        if elapsedSeconds >= targetSeconds {
            finishOnComplete()
        }
    }

    private func finishOnComplete() {
        guard phase == .running else { return }
        bankedElapsed = Double(targetSeconds)
        startInstant = nil
        invalidateTimer()
        elapsedSeconds = targetSeconds
        phase = .finished
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func currentElapsed() -> TimeInterval {
        if let start = startInstant {
            return bankedElapsed + Date().timeIntervalSince(start)
        }
        return bankedElapsed
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Persistence

    /// Build and insert a `PracticeSession` for the elapsed time, attributed across
    /// the given pieces. Returns nil (and inserts nothing) if no piece is selected —
    /// a session must be about *something*. Time splits evenly across pieces.
    @discardableResult
    func writeSession(into context: ModelContext,
                      pieces: [Piece],
                      bpm: Int,
                      focusNotes: String,
                      quality: SessionQuality?,
                      at date: Date = .now) -> PracticeSession? {
        let played = pieces.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !played.isEmpty else { return nil }
        let seconds = max(0, elapsedSeconds)
        guard seconds > 0 else { return nil }

        let session = PracticeSession(
            date: date,
            durationSeconds: seconds,
            focusNotes: focusNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            quality: quality,
            tempo: Tempo.clamp(bpm)
        )
        context.insert(session)

        // Even split; the first entry absorbs the rounding remainder so totals reconcile.
        let base = seconds / played.count
        let remainder = seconds - base * played.count
        for (idx, piece) in played.enumerated() {
            let entry = SessionEntry(durationSeconds: base + (idx == 0 ? remainder : 0))
            entry.session = session
            entry.piece = piece
            session.entries.append(entry)
            context.insert(entry)
        }
        return session
    }
}
