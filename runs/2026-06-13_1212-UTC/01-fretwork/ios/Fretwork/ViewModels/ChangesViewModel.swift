import Foundation
import SwiftData

/// Drives the "one-minute chord changes" drill (the classic Justin-Guitar
/// exercise): pick two chords, then tap once per clean change for the duration.
/// Reports changes-per-minute and logs a session.
@Observable
final class ChangesViewModel {
    enum Phase { case ready, running, done }

    var chordA: Chord
    var chordB: Chord
    var durationSeconds: Int
    var phase: Phase = .ready
    var remaining: Int
    var changes = 0
    /// Which chord the learner should currently be moving *to* (visual cue).
    var onA = true

    private var timer: Timer?

    init(chordA: Chord, chordB: Chord, durationSeconds: Int) {
        self.chordA = chordA
        self.chordB = chordB
        self.durationSeconds = durationSeconds
        self.remaining = durationSeconds
    }

    /// Changes-per-minute, normalised to a full minute.
    var cpm: Int {
        let elapsed = max(1, durationSeconds - remaining)
        if phase == .done {
            return Int((Double(changes) * 60.0 / Double(durationSeconds)).rounded())
        }
        return Int((Double(changes) * 60.0 / Double(elapsed)).rounded())
    }

    func start() {
        changes = 0
        onA = true
        remaining = durationSeconds
        phase = .running
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard phase == .running else { return }
        remaining -= 1
        if remaining <= 0 {
            remaining = 0
            finish()
        }
    }

    /// Record one clean chord change.
    func tapChange() {
        guard phase == .running else { return }
        changes += 1
        onA.toggle()
        Haptics.tap()
    }

    func finish() {
        timer?.invalidate()
        timer = nil
        if phase == .running {
            phase = .done
            Haptics.success()
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        phase = .ready
        remaining = durationSeconds
        changes = 0
        onA = true
    }

    @discardableResult
    func save(to context: ModelContext) -> Int {
        let label = "\(chordA.symbol) ⇄ \(chordB.symbol)"
        let session = PracticeSession(
            kind: .changes, durationSeconds: durationSeconds,
            primaryMetric: cpm, secondaryMetric: changes, label: label)
        context.insert(session)
        try? context.save()
        return cpm
    }

    deinit { timer?.invalidate() }
}
