import SwiftUI

/// Drives a live meditation sit. Time is derived from a stored start date so the
/// countdown stays accurate across backgrounding; bells fire as the elapsed time
/// crosses warm-up, interval, and end boundaries.
@MainActor
@Observable
final class SessionEngine {
    enum Phase { case idle, warmup, meditating, finished }

    private(set) var phase: Phase = .idle
    private(set) var elapsed: Int = 0
    private(set) var completedFully = false

    var isPaused = false

    private var preset: MeditationPreset?
    private var presetName = ""
    private var warmup = 0
    private var meditationSeconds = 0
    private var total = 0
    private var intervalOffsets: [Int] = []
    private var startBell: BellTone = .bowl
    private var intervalBell: BellTone = .chime
    private var endBell: BellTone = .bowl

    private var startDate: Date?
    private var firedIntervals: Set<Int> = []
    private var startBellFired = false
    private var timer: Timer?

    var hapticsOnBell = true

    // MARK: - Lifecycle

    func start(_ preset: MeditationPreset) {
        self.preset = preset
        presetName = preset.name
        warmup = preset.warmupSeconds
        meditationSeconds = preset.minutes * 60
        total = preset.totalSeconds
        intervalOffsets = preset.intervalOffsets
        startBell = preset.startBell
        intervalBell = preset.intervalBell
        endBell = preset.endBell

        elapsed = 0
        firedIntervals = []
        startBellFired = false
        completedFully = false
        isPaused = false
        startDate = Date()

        if warmup == 0 {
            phase = .meditating
            ringStart()
        } else {
            phase = .warmup
        }
        scheduleTimer()
    }

    func pause() {
        guard phase == .warmup || phase == .meditating, !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        // Shift the start date so derived elapsed continues seamlessly.
        startDate = Date().addingTimeInterval(-Double(elapsed))
        scheduleTimer()
    }

    func endEarly() {
        guard phase == .warmup || phase == .meditating else { return }
        completedFully = false
        finish(ringBell: false)
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        elapsed = 0
        isPaused = false
        startDate = nil
        BellPlayer.shared.deactivate()
    }

    // MARK: - Derived display

    var remaining: Int { max(0, total - elapsed) }

    var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(elapsed) / Double(total))
    }

    var phaseLabel: String {
        switch phase {
        case .idle: return "Ready"
        case .warmup: return "Settle in"
        case .meditating: return "Meditating"
        case .finished: return completedFully ? "Complete" : "Ended"
        }
    }

    /// Seconds remaining shown to the user (whole sit).
    var displayRemaining: Int { remaining }

    // MARK: - Building a log

    func buildSession() -> MeditationSession {
        MeditationSession(
            presetName: presetName.isEmpty ? "Sit" : presetName,
            plannedSeconds: total,
            actualSeconds: min(elapsed, total),
            completed: completedFully
        )
    }

    // MARK: - Internals

    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard let startDate, !isPaused else { return }
        let now = Int(Date().timeIntervalSince(startDate))
        elapsed = max(0, min(now, total))

        if phase == .warmup, elapsed >= warmup {
            phase = .meditating
            ringStart()
        }

        if phase == .meditating {
            let medElapsed = elapsed - warmup
            for offset in intervalOffsets where medElapsed >= offset && !firedIntervals.contains(offset) {
                firedIntervals.insert(offset)
                ring(intervalBell)
            }
        }

        if elapsed >= total {
            completedFully = true
            finish(ringBell: true)
        }
    }

    private func ringStart() {
        guard !startBellFired else { return }
        startBellFired = true
        ring(startBell)
    }

    private func ring(_ tone: BellTone) {
        BellPlayer.shared.play(tone)
        if hapticsOnBell { Haptics.tap() }
    }

    private func finish(ringBell: Bool) {
        timer?.invalidate()
        timer = nil
        phase = .finished
        if ringBell { ring(endBell) }
    }
}
