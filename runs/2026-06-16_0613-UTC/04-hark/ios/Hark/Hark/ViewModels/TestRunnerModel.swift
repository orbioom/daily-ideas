import SwiftUI
import SwiftData

/// Drives a live screening: owns the AudioEngine + ThresholdProcedure and a timing loop.
/// `@Observable` + `@State` ownership in the view.
@Observable
@MainActor
final class TestRunnerModel {

    enum Phase: Equatable {
        case idle
        case presenting          // a tone is (or is about to be) playing; awaiting response
        case betweenStimuli      // brief silent gap
        case finished
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var currentEar: Ear = .right
    private(set) var currentFrequency: Int = 1000
    private(set) var progress: Double = 0
    private(set) var isPaused = false
    /// True only while the audible tone is actually sounding (for UI cue + a11y).
    private(set) var toneAudible = false

    /// Accumulated thresholds as the test runs: [ear: [freq: db]].
    private(set) var results: [Ear: [Int: Double]] = [.left: [:], .right: [:]]

    private let audio = AudioEngine()
    private var procedure: ThresholdProcedure
    private let config: ProcedureConfig
    private let toneDuration: Double
    private let responseTimeout: Double
    private let maxLevel: Double

    /// Cancellable async task for the current presentation cycle.
    private var cycleTask: Task<Void, Never>?
    private var currentLevel: Double = 0
    private var responded = false
    /// Only true from the moment a tone becomes audible until the response window closes.
    /// Taps during the silent jitter pre-delay are ignored, so users can't "win" by mashing.
    private var responseWindowOpen = false

    init(settings: AppSettings) {
        let cfg = ProcedureConfig(
            earOrder: settings.earOrder,
            maxLevel: settings.maxTestLevel,
            startLevel: 40,
            minLevel: Audiometry.minLevel
        )
        self.config = cfg
        self.procedure = ThresholdProcedure(config: cfg, rng: SystemRandomProvider())
        self.toneDuration = settings.toneDuration
        self.responseTimeout = settings.responseTimeout
        self.maxLevel = settings.maxTestLevel
    }

    func begin() {
        do {
            try audio.prepare()
        } catch {
            phase = .error((error as? AudioEngineError)?.errorDescription ?? "Audio is unavailable right now.")
            return
        }
        let first = procedure.start()
        runPresentation(first)
    }

    /// Run one presentation: silent jittered pre-delay, audible tone, then a response window.
    private func runPresentation(_ p: Presentation) {
        cycleTask?.cancel()
        currentEar = p.ear
        currentFrequency = p.frequency
        currentLevel = p.level
        progress = procedure.progress
        responded = false
        responseWindowOpen = false
        phase = .presenting

        cycleTask = Task { [weak self] in
            guard let self else { return }
            // Silent pre-delay (jitter) so users can't time a rhythm.
            await self.sleepRespectingPause(p.preDelay)
            if Task.isCancelled { return }

            // Audible tone for toneDuration. The response window opens now.
            self.responseWindowOpen = true
            self.audio.start(frequency: p.frequency, level: p.level, maxLevel: self.maxLevel, ear: p.ear)
            self.toneAudible = true
            await self.sleepRespectingPause(self.toneDuration)
            self.audio.stop()
            self.toneAudible = false
            if Task.isCancelled { return }

            // If the user already responded during the tone, we've moved on. Otherwise keep
            // the response window open a little longer, then count as "no response".
            if self.responded { return }
            await self.sleepRespectingPause(self.responseTimeout)
            if Task.isCancelled { return }
            if !self.responded {
                self.responseWindowOpen = false
                self.handle(heard: false)
            }
        }
    }

    /// Sleep that pauses while `isPaused` is true (polled).
    private func sleepRespectingPause(_ seconds: Double) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if Task.isCancelled { return }
            if isPaused {
                try? await Task.sleep(nanoseconds: 100_000_000)
                continue
            }
            let remaining = deadline.timeIntervalSinceNow
            let chunk = min(0.05, max(0, remaining))
            if chunk <= 0 { break }
            try? await Task.sleep(nanoseconds: UInt64(chunk * 1_000_000_000))
        }
    }

    /// User pressed "I hear a tone".
    func userHeard() {
        guard case .presenting = phase, responseWindowOpen, !responded else { return }
        responded = true
        responseWindowOpen = false
        cycleTask?.cancel()
        audio.stop()
        toneAudible = false
        handle(heard: true)
    }

    private func handle(heard: Bool) {
        let outcome = procedure.record(heard: heard)
        switch outcome {
        case .present(let p):
            phase = .betweenStimuli
            runPresentation(p)
        case .frequencyComplete(let ear, let freq, let threshold):
            if let threshold {
                results[ear, default: [:]][freq] = threshold
            }
            if let next = procedure.nextAfterFrequency() {
                phase = .betweenStimuli
                runPresentation(next)
            } else {
                complete()
            }
        case .testComplete:
            complete()
        }
        progress = procedure.progress
    }

    private func complete() {
        cycleTask?.cancel()
        audio.stop()
        toneAudible = false
        progress = 1
        phase = .finished
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            audio.stop()
            toneAudible = false
        }
    }

    /// Abort and tear down without saving.
    func quit() {
        cycleTask?.cancel()
        audio.teardown()
        toneAudible = false
        phase = .idle
    }

    /// Persist the completed test into SwiftData. Returns the saved test (or nil on failure).
    @discardableResult
    func save(into context: ModelContext) -> HearingTest? {
        let left = results[.left] ?? [:]
        let right = results[.right] ?? [:]
        let test = HearingTest(date: .now, maxLevelUsed: maxLevel)
        test.ptaLeft = Audiometry.pta(from: left)
        test.ptaRight = Audiometry.pta(from: right)
        context.insert(test)
        for (f, db) in left { context.insert(Threshold(ear: .left, frequency: f, dbLevel: db, test: test)) }
        for (f, db) in right { context.insert(Threshold(ear: .right, frequency: f, dbLevel: db, test: test)) }
        do {
            try context.save()
            audio.teardown()
            return test
        } catch {
            return nil
        }
    }

    func teardown() {
        cycleTask?.cancel()
        audio.teardown()
    }
}
