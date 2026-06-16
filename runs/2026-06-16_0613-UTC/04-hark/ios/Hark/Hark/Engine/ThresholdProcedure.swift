import Foundation

/// A simple injectable RNG so the engine is deterministic in tests but jittered in production.
protocol RandomProvider {
    /// Returns a value in [0, 1).
    mutating func nextUnit() -> Double
}

struct SystemRandomProvider: RandomProvider {
    private var generator = SystemRandomNumberGenerator()
    mutating func nextUnit() -> Double { Double.random(in: 0..<1, using: &generator) }
}

/// Deterministic provider for previews/seed reproducibility.
struct SeededRandomProvider: RandomProvider {
    private var generator: SeededGenerator
    init(seed: UInt64) { generator = SeededGenerator(seed: seed) }
    mutating func nextUnit() -> Double { Double.random(in: 0..<1, using: &generator) }
}

/// Small splitmix64 generator — deterministic, good enough for jitter/seed.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// One tone presentation the runner should play, with its jittered pre-delay.
struct Presentation: Equatable {
    let ear: Ear
    let frequency: Int
    let level: Double
    /// Seconds to wait (silently) before presenting this tone — defeats rhythm-gaming.
    let preDelay: Double
}

/// Result of feeding a response (or timeout) back into the procedure.
enum StepOutcome: Equatable {
    /// Present the next tone.
    case present(Presentation)
    /// This frequency/ear finished; threshold recorded (or nil if floor/ceiling reached).
    case frequencyComplete(ear: Ear, frequency: Int, threshold: Double?)
    /// The entire test finished.
    case testComplete
}

/// Configuration for a screening run.
struct ProcedureConfig {
    var earOrder: EarOrder
    var maxLevel: Double
    var startLevel: Double = 40
    var minLevel: Double = Audiometry.minLevel
    /// Jitter window added before each presentation (seconds).
    var jitterRange: ClosedRange<Double> = 0.3...1.2
}

/// Modified Hughson–Westlake up-down threshold search.
///
/// Rule: present a tone.
///   • "I hear it"  -> drop level by 10 dB.
///   • no response  -> raise level by 5 dB.
/// A threshold is the lowest level with responses on at least 2 of 3 ASCENDING presentations
/// at that level. We track "heard at this level on the way up" tallies per level.
///
/// The procedure is a pure state machine: the runner plays a `Presentation`, then calls
/// `record(heard:)`. No timers, no audio, no UI live here.
final class ThresholdProcedure {
    let config: ProcedureConfig
    private var rng: RandomProvider

    private let earSequence: [Ear]
    private var earIndex = 0
    private var freqIndex = 0

    private var currentLevel: Double
    private var lastDirectionWasDown = false
    /// For the current ear+freq: count of "heard" responses recorded at each level during ascents.
    private var ascendingHeardCount: [Double: Int] = [:]
    /// Total presentations at each level (cap to avoid runaway loops).
    private var presentationsAtLevel: [Double: Int] = [:]
    private var totalPresentationsThisFreq = 0

    private(set) var isFinished = false

    init(config: ProcedureConfig, rng: RandomProvider = SystemRandomProvider()) {
        self.config = config
        self.rng = rng
        self.earSequence = [config.earOrder.firstEar, config.earOrder.secondEar]
        self.currentLevel = config.startLevel
    }

    private var currentEar: Ear { earSequence[min(earIndex, earSequence.count - 1)] }
    private var currentFrequency: Int { Audiometry.frequencies[min(freqIndex, Audiometry.frequencies.count - 1)] }

    private func jitter() -> Double {
        let span = config.jitterRange.upperBound - config.jitterRange.lowerBound
        return config.jitterRange.lowerBound + rng.nextUnit() * span
    }

    /// The very first presentation to begin the test.
    func start() -> Presentation {
        resetFrequencyState()
        return Presentation(ear: currentEar, frequency: currentFrequency, level: currentLevel, preDelay: jitter())
    }

    private func resetFrequencyState() {
        currentLevel = config.startLevel
        lastDirectionWasDown = false
        ascendingHeardCount.removeAll()
        presentationsAtLevel.removeAll()
        totalPresentationsThisFreq = 0
    }

    /// Feed back a single response. `heard == true` means the user pressed "I hear a tone";
    /// `heard == false` means the response window timed out.
    func record(heard: Bool) -> StepOutcome {
        guard !isFinished else { return .testComplete }

        let levelJustPlayed = currentLevel
        presentationsAtLevel[levelJustPlayed, default: 0] += 1
        totalPresentationsThisFreq += 1

        if heard {
            // Count this as an ascending "heard" only if we arrived here going UP (last move was up),
            // i.e. this is a confirmation on the way up. The first descent presentations don't count.
            if !lastDirectionWasDown {
                ascendingHeardCount[levelJustPlayed, default: 0] += 1
            }

            // Threshold criterion: 2 of 3 ascending responses at a level.
            if (ascendingHeardCount[levelJustPlayed] ?? 0) >= 2 {
                return finishFrequency(threshold: levelJustPlayed)
            }

            // Heard -> go down 10.
            let next = max(config.minLevel, currentLevel - Audiometry.levelStepDown)
            if next == currentLevel {
                // Already at floor and still hearing -> floor is the threshold estimate.
                return finishFrequency(threshold: config.minLevel)
            }
            currentLevel = next
            lastDirectionWasDown = true
        } else {
            // No response -> go up 5.
            let next = min(config.maxLevel, currentLevel + Audiometry.levelStepUp)
            if next == currentLevel {
                // Hit the ceiling without a reliable response -> no measurable threshold this freq.
                return finishFrequency(threshold: nil)
            }
            currentLevel = next
            lastDirectionWasDown = false
        }

        // Safety cap: prevent pathological loops (should never trigger with sane config).
        if totalPresentationsThisFreq > 40 {
            let best = ascendingHeardCount.keys.min()
            return finishFrequency(threshold: best)
        }

        return .present(Presentation(ear: currentEar, frequency: currentFrequency, level: currentLevel, preDelay: jitter()))
    }

    private func finishFrequency(threshold: Double?) -> StepOutcome {
        let ear = currentEar
        let freq = currentFrequency
        advance()
        return .frequencyComplete(ear: ear, frequency: freq, threshold: threshold)
    }

    /// Advance to the next frequency, then the next ear, else finish.
    private func advance() {
        freqIndex += 1
        if freqIndex >= Audiometry.frequencies.count {
            freqIndex = 0
            earIndex += 1
        }
        if earIndex >= earSequence.count {
            isFinished = true
        } else {
            resetFrequencyState()
        }
    }

    /// The next presentation after a `frequencyComplete`, or nil if the test is done.
    func nextAfterFrequency() -> Presentation? {
        guard !isFinished else { return nil }
        return Presentation(ear: currentEar, frequency: currentFrequency, level: currentLevel, preDelay: jitter())
    }

    /// Progress 0...1 across all ear×frequency cells.
    var progress: Double {
        let total = Double(earSequence.count * Audiometry.frequencies.count)
        let done = Double(earIndex * Audiometry.frequencies.count + freqIndex)
        return min(1, max(0, done / total))
    }
}
