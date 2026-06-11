import Foundation
import CoreMotion
import Observation

/// Round state machine + tilt detection. The phone is held to the forehead,
/// screen out: tilting the screen toward the floor scores, toward the
/// ceiling passes; the device must return near vertical to re-arm.
@Observable
final class GameEngine {
    enum Phase: Equatable {
        case getReady(remaining: Int)
        case playing
        case flash(correct: Bool)
        case finished
    }

    enum TiltAvailability { case available, unavailable }

    private(set) var phase: Phase = .getReady(remaining: 3)
    private(set) var currentWord: String = ""
    private(set) var correctWords: [String] = []
    private(set) var passedWords: [String] = []
    private(set) var endDate: Date = .distantFuture
    private(set) var tilt: TiltAvailability = .unavailable

    let deck: PlayableDeck
    let roundSeconds: Int
    let tiltEnabled: Bool

    private var queue: [String]
    private let motion = CMMotionManager()
    private var armed = true
    private var countdownTask: Task<Void, Never>?
    var onCorrect: (() -> Void)?
    var onPass: (() -> Void)?
    var onFinish: (() -> Void)?

    var score: Int { correctWords.count }
    var totalSeen: Int { correctWords.count + passedWords.count }

    init(deck: PlayableDeck, roundSeconds: Int, tiltEnabled: Bool = true) {
        self.deck = deck
        self.roundSeconds = roundSeconds
        self.tiltEnabled = tiltEnabled
        self.queue = deck.words.shuffled()
        self.currentWord = queue.first ?? ""
    }

    // MARK: - Lifecycle

    func begin() {
        countdownTask = Task { @MainActor [weak self] in
            var remaining = 3
            while remaining > 0 {
                self?.phase = .getReady(remaining: remaining)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                remaining -= 1
            }
            self?.startRound()
        }
        if tiltEnabled { startMotion() }
    }

    func cancel() {
        countdownTask?.cancel()
        motion.stopDeviceMotionUpdates()
        if phase != .finished { phase = .finished }
    }

    private func startRound() {
        endDate = Date.now.addingTimeInterval(TimeInterval(roundSeconds))
        phase = .playing
        Task { @MainActor [weak self] in
            while let self, self.phase == .playing || self.isFlashing {
                if Date.now >= self.endDate {
                    self.finish()
                    return
                }
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    private var isFlashing: Bool {
        if case .flash = phase { return true }
        return false
    }

    private func finish() {
        guard phase != .finished else { return }
        motion.stopDeviceMotionUpdates()
        phase = .finished
        onFinish?()
    }

    func remainingSeconds(at date: Date) -> Int {
        max(0, Int(endDate.timeIntervalSince(date).rounded(.up)))
    }

    // MARK: - Scoring

    func markCorrect() {
        guard phase == .playing else { return }
        correctWords.append(currentWord)
        onCorrect?()
        flashThenAdvance(correct: true)
    }

    func markPass() {
        guard phase == .playing else { return }
        passedWords.append(currentWord)
        onPass?()
        flashThenAdvance(correct: false)
    }

    private func flashThenAdvance(correct: Bool) {
        phase = .flash(correct: correct)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard let self, case .flash = self.phase else { return }
            self.advanceWord()
            if Date.now >= self.endDate {
                self.finish()
            } else {
                self.phase = .playing
            }
        }
    }

    private func advanceWord() {
        if !queue.isEmpty { queue.removeFirst() }
        if queue.isEmpty {
            // Recycle passed words so the round never runs dry.
            queue = (passedWords + deck.words).shuffled()
        }
        currentWord = queue.first ?? ""
    }

    // MARK: - Tilt

    private func startMotion() {
        guard motion.isDeviceMotionAvailable else {
            tilt = .unavailable
            return
        }
        tilt = .available
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let gravity = data?.gravity else { return }
            let z = gravity.z
            if self.armed {
                if z > 0.62 {            // screen toward the floor → correct
                    self.armed = false
                    self.markCorrect()
                } else if z < -0.62 {    // screen toward the ceiling → pass
                    self.armed = false
                    self.markPass()
                }
            } else if abs(z) < 0.32 {    // back near vertical → re-arm
                self.armed = true
            }
        }
    }
}
