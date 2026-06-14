import SwiftUI
import SwiftData

/// Drives a running sight-reading drill. Owned by the Practice view as `@State`
/// (an `@Observable` type — do NOT wrap in `@StateObject`).
@Observable
@MainActor
final class DrillEngine {

    enum Phase: Equatable {
        case idle
        case running
        case finished
    }

    // MARK: Observable state
    private(set) var phase: Phase = .idle
    private(set) var config: DrillConfig
    private(set) var currentMIDI: Int = 60
    private(set) var correct: Int = 0
    private(set) var total: Int = 0
    private(set) var streak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var elapsedSec: Int = 0
    /// Last answer feedback: nil = awaiting, true = correct, false = wrong.
    private(set) var lastWasCorrect: Bool? = nil
    /// When wrong, the correct spelling to surface to the user.
    private(set) var revealName: String? = nil
    /// Finished result, ready to persist (set once at finish).
    private(set) var result: DrillSession?

    // MARK: Collaborators (not observed)
    @ObservationIgnored private weak var context: ModelContext?
    @ObservationIgnored private var settings: AppSettings?

    // MARK: Internal
    @ObservationIgnored private var pool: [Int] = []
    @ObservationIgnored private var responseMs: [Double] = []
    @ObservationIgnored private var questionStart: Date = Date()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var statCache: [Int: (seen: Int, correct: Int)] = [:]
    @ObservationIgnored private var rng = SystemRandomNumberGenerator()
    @ObservationIgnored private var locked = false

    init(config: DrillConfig) {
        self.config = config
    }

    var useFlats: Bool { settings?.useFlats ?? false }

    /// Notes answered so far / target (for the progress display in fixed mode).
    var targetCount: Int { config.length }

    var remainingSec: Int { max(0, DrillConfig.timedDurationSec - elapsedSec) }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var avgMs: Double {
        guard !responseMs.isEmpty else { return 0 }
        return responseMs.reduce(0, +) / Double(responseMs.count)
    }

    // MARK: - Lifecycle

    func start(context: ModelContext, settings: AppSettings) {
        self.context = context
        self.settings = settings
        pool = config.notePool()
        guard !pool.isEmpty else {
            // Defensive: nothing to drill. Mark finished with an empty result.
            phase = .finished
            return
        }
        correct = 0
        total = 0
        streak = 0
        bestStreak = 0
        elapsedSec = 0
        responseMs.removeAll()
        lastWasCorrect = nil
        revealName = nil
        result = nil
        locked = false
        loadStatCache()
        phase = .running
        nextNote()
        if config.mode == .timed { startTimer() }
    }

    private func loadStatCache() {
        statCache.removeAll()
        guard let context else { return }
        let clefKeyPrefix = config.clef.rawValue
        let descriptor = FetchDescriptor<NoteStat>()
        if let all = try? context.fetch(descriptor) {
            for stat in all where stat.key.hasPrefix(clefKeyPrefix + ":") {
                if let midi = NoteStat.midi(fromKey: stat.key) {
                    statCache[midi] = (stat.seen, stat.correct)
                }
            }
        }
    }

    // MARK: - Note selection (mastery-weighted)

    /// Choose the next target, favoring notes with worse accuracy and the unseen.
    private func nextNote() {
        guard !pool.isEmpty else { return }
        let previous = currentMIDI
        var weights: [Double] = []
        for midi in pool {
            let stat = statCache[midi]
            let seen = stat?.seen ?? 0
            let corr = stat?.correct ?? 0
            // Mastery 0...1; lower mastery → higher weight. Unseen gets a strong boost.
            let mastery = seen > 0 ? Double(corr) / Double(seen) : 0
            var w = 0.25 + (1.0 - mastery)        // 0.25...1.25 base
            if seen == 0 { w += 0.6 }             // explore unseen notes
            if midi == previous && pool.count > 1 { w *= 0.25 } // avoid immediate repeats
            weights.append(max(0.01, w))
        }
        currentMIDI = weightedPick(pool, weights: weights) ?? pool[0]
        lastWasCorrect = nil
        revealName = nil
        locked = false
        questionStart = Date()
    }

    private func weightedPick(_ items: [Int], weights: [Double]) -> Int? {
        guard items.count == weights.count, !items.isEmpty else { return items.first }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else { return items.first }
        let r = Double.random(in: 0..<totalWeight, using: &rng)
        var acc = 0.0
        for (i, w) in weights.enumerated() {
            acc += w
            if r < acc { return items[i] }
        }
        return items.last
    }

    // MARK: - Answering

    /// Submit an answer. Returns whether it was correct (nil if not running/locked).
    @discardableResult
    func submit(letter: String, accidental: Accidental) -> Bool? {
        guard phase == .running, !locked else { return nil }
        locked = true

        let isRight = MusicTheory.isCorrect(answerLetter: letter,
                                            accidental: accidental,
                                            target: currentMIDI,
                                            useFlats: useFlats)
        let elapsedMs = Date().timeIntervalSince(questionStart) * 1000
        responseMs.append(elapsedMs)
        total += 1
        if isRight {
            correct += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            lastWasCorrect = true
            revealName = nil
        } else {
            streak = 0
            lastWasCorrect = false
            revealName = Pitch(currentMIDI).name(useFlats: useFlats)
        }
        updateStat(midi: currentMIDI, correct: isRight)

        let h = settings?.hapticsEnabled ?? false
        if isRight { Haptics.success(h) } else { Haptics.error(h) }

        // When the fixed count is reached, `advance()` (called after the feedback
        // flash) will transition to the finished phase.
        return isRight
    }

    /// Advance to the next note after the feedback flash (called by the view).
    func advance() {
        guard phase == .running else { return }
        if config.mode == .fixedCount && total >= config.length {
            finish()
            return
        }
        nextNote()
    }

    private func updateStat(midi: Int, correct isRight: Bool) {
        let prior = statCache[midi] ?? (0, 0)
        statCache[midi] = (prior.seen + 1, prior.correct + (isRight ? 1 : 0))
        guard let context else { return }
        let key = NoteStat.makeKey(clef: config.clef, midi: midi)
        let descriptor = FetchDescriptor<NoteStat>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.seen += 1
            if isRight { existing.correct += 1 }
            existing.lastSeen = Date()
        } else {
            let stat = NoteStat(key: key, seen: 1, correct: isRight ? 1 : 0, lastSeen: Date())
            context.insert(stat)
        }
        try? context.save()
    }

    // MARK: - Timer (timed mode)

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard phase == .running, config.mode == .timed else { return }
        elapsedSec += 1
        if elapsedSec >= DrillConfig.timedDurationSec {
            finish()
        }
    }

    // MARK: - Pause / finish

    /// Pause cleanly (e.g. leaving the screen) without recording a result.
    func pause() {
        stopTimer()
    }

    func finish() {
        guard phase == .running else { return }
        stopTimer()
        phase = .finished
        let duration = config.mode == .timed ? min(elapsedSec, DrillConfig.timedDurationSec)
                                             : elapsedSec
        let session = DrillSession(clef: config.clef,
                                   mode: config.mode,
                                   total: total,
                                   correct: correct,
                                   durationSec: duration,
                                   avgMs: avgMs,
                                   bestStreak: bestStreak)
        result = session
        if let context, total > 0 {
            context.insert(session)
            try? context.save()
        }
        Haptics.success(settings?.hapticsEnabled ?? false)
    }

    /// Restart with the same config (used by the "Again" button).
    func again(context: ModelContext, settings: AppSettings) {
        start(context: context, settings: settings)
    }
}
