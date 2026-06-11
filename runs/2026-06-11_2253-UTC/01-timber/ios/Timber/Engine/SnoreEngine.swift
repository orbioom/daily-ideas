import Foundation

/// Pure scoring + statistics for nights and factors. No UI, no I/O.
enum SnoreEngine {

    // MARK: Snore Score

    /// 0–100. Transparent formula: intensity-weighted snoring time as a share of
    /// the night, scaled so that snoring 25% of the night at "loud" maps to 100.
    static func score(for session: NightSession) -> Int {
        score(duration: session.duration, episodes: session.episodes.map {
            (intensity: $0.intensity, duration: $0.duration)
        })
    }

    static func score(duration: TimeInterval,
                      episodes: [(intensity: SnoreIntensity, duration: TimeInterval)]) -> Int {
        guard duration > 60 else { return 0 }
        let weighted = episodes.reduce(0.0) { $0 + $1.duration * $1.intensity.weight }
        let ceilingSeconds = duration * 0.25
        guard ceilingSeconds > 0 else { return 0 }
        return min(100, Int((weighted / ceilingSeconds * 100).rounded()))
    }

    static func grade(forScore score: Int) -> (label: String, detail: String) {
        switch score {
        case ..<10: return ("Quiet", "Barely a whisper all night.")
        case ..<25: return ("Light", "A few gentle rumbles.")
        case ..<50: return ("Moderate", "Noticeable snoring for parts of the night.")
        case ..<75: return ("Heavy", "Sustained snoring — worth investigating.")
        default: return ("Epic", "The full lumberjack. Try a remedy tonight.")
        }
    }

    /// Share (0...1) of the night spent snoring at any intensity.
    static func snorePercent(for session: NightSession) -> Double {
        guard session.duration > 0 else { return 0 }
        let total = session.episodes.reduce(0.0) { $0 + $1.duration }
        return min(total / session.duration, 1)
    }

    static func intensityBreakdown(for session: NightSession) -> [SnoreIntensity: TimeInterval] {
        var out: [SnoreIntensity: TimeInterval] = [:]
        for ep in session.episodes {
            out[ep.intensity, default: 0] += ep.duration
        }
        return out
    }

    // MARK: Trends

    /// Average score per weekday (1 = Sunday … 7 = Saturday), only weekdays with data.
    static func weekdayAverages(sessions: [NightSession], calendar: Calendar = .current) -> [(weekday: Int, average: Double)] {
        var sums: [Int: (total: Double, count: Int)] = [:]
        for s in sessions {
            let wd = calendar.component(.weekday, from: s.startedAt)
            let sc = Double(score(for: s))
            let prev = sums[wd] ?? (0, 0)
            sums[wd] = (prev.total + sc, prev.count + 1)
        }
        return sums.map { (weekday: $0.key, average: $0.value.total / Double(max($0.value.count, 1))) }
            .sorted { $0.weekday < $1.weekday }
    }

    // MARK: Factor impact

    struct FactorImpact: Identifiable {
        var id: String { name }
        let name: String
        let emoji: String
        /// Average score on nights WITH the factor.
        let withAverage: Double
        /// Average score on nights WITHOUT it.
        let withoutAverage: Double
        let nightsWith: Int
        /// Negative delta = factor is associated with quieter nights.
        var delta: Double { withAverage - withoutAverage }
    }

    /// Compares average Snore Score with vs. without each factor.
    /// Requires at least 2 nights on each side to report a factor.
    static func factorImpacts(sessions: [NightSession], factors: [SleepFactor]) -> [FactorImpact] {
        guard sessions.count >= 4 else { return [] }
        let scored = sessions.map { (session: $0, score: Double(score(for: $0))) }
        var out: [FactorImpact] = []
        for factor in factors {
            let withNights = scored.filter { $0.session.factors.contains(where: { $0.name == factor.name }) }
            let withoutNights = scored.filter { !$0.session.factors.contains(where: { $0.name == factor.name }) }
            guard withNights.count >= 2, withoutNights.count >= 2 else { continue }
            let wAvg = withNights.reduce(0.0) { $0 + $1.score } / Double(withNights.count)
            let woAvg = withoutNights.reduce(0.0) { $0 + $1.score } / Double(withoutNights.count)
            out.append(FactorImpact(name: factor.name, emoji: factor.emoji,
                                    withAverage: wAvg, withoutAverage: woAvg,
                                    nightsWith: withNights.count))
        }
        return out.sorted { abs($0.delta) > abs($1.delta) }
    }

    // MARK: Formatting

    static func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(total % 60)s"
    }
}

/// Live snore detection over a stream of metered dB samples (2 per second).
/// Adaptive: tracks the room's noise floor and flags sustained loud stretches.
struct SnoreDetector {
    /// dB above the tracked noise floor required to count as snoring.
    var sensitivity: Double = 14
    private(set) var noiseFloor: Double = -50
    private var aboveCount = 0
    private var belowCount = 0
    private var currentStart: TimeInterval?
    private var currentPeak: Double = -160
    private var sampleInterval: TimeInterval

    init(sampleInterval: TimeInterval = 0.5, sensitivity: Double = 14) {
        self.sampleInterval = sampleInterval
        self.sensitivity = sensitivity
    }

    struct Detected {
        let startOffset: TimeInterval
        let duration: TimeInterval
        let peakDB: Double
        var intensity: SnoreIntensity {
            if peakDB > -18 { return .epic }
            if peakDB > -30 { return .loud }
            return .mild
        }
    }

    var threshold: Double { max(noiseFloor + sensitivity, -46) }
    var isInEpisode: Bool { currentStart != nil }

    /// Feed one dB sample; returns a finished episode when one closes.
    mutating func ingest(db: Double, at offset: TimeInterval) -> Detected? {
        if db < threshold {
            // Slowly adapt the floor only from quiet samples.
            noiseFloor = noiseFloor * 0.98 + db * 0.02
        }
        if db >= threshold {
            aboveCount += 1
            belowCount = 0
            currentPeak = max(currentPeak, db)
            if currentStart == nil, aboveCount >= 4 { // ~2s sustained
                currentStart = offset - Double(aboveCount) * sampleInterval
            }
        } else {
            belowCount += 1
            aboveCount = 0
            if let start = currentStart, belowCount >= 6 { // ~3s of quiet ends it
                let episode = Detected(startOffset: max(start, 0),
                                       duration: max(offset - Double(belowCount) * sampleInterval - start, sampleInterval),
                                       peakDB: currentPeak)
                currentStart = nil
                currentPeak = -160
                return episode.duration >= 2 ? episode : nil
            }
        }
        return nil
    }

    /// Close any open episode at session end.
    mutating func flush(at offset: TimeInterval) -> Detected? {
        guard let start = currentStart else { return nil }
        let episode = Detected(startOffset: max(start, 0),
                               duration: max(offset - start, sampleInterval),
                               peakDB: currentPeak)
        currentStart = nil
        currentPeak = -160
        return episode.duration >= 2 ? episode : nil
    }
}
