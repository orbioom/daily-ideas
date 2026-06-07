import Foundation

/// The four ordered stages of a black-and-white developing run.
enum PhaseKind: String, CaseIterable, Codable, Identifiable {
    case develop = "Develop"
    case stop    = "Stop"
    case fix     = "Fix"
    case wash    = "Wash"

    var id: String { rawValue }

    var title: String { rawValue }

    /// SF Symbol used in the timer and previews.
    var symbol: String {
        switch self {
        case .develop: return "drop.fill"
        case .stop:    return "hand.raised.fill"
        case .fix:     return "lock.fill"
        case .wash:    return "shower.fill"
        }
    }

    /// A short reminder shown beneath the phase title.
    var hint: String {
        switch self {
        case .develop: return "Agitate as noted, then let it work."
        case .stop:    return "Brief stop bath halts development."
        case .fix:     return "Fixer makes the image permanent."
        case .wash:    return "Wash thoroughly to clear fixer."
        }
    }
}

/// One concrete phase in a run: a kind, its duration, and how often to agitate
/// (0 = no agitation reminders for this phase).
struct Phase: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: PhaseKind
    var seconds: Int
    var agitationEverySec: Int

    init(id: UUID = UUID(), kind: PhaseKind, seconds: Int, agitationEverySec: Int) {
        self.id = id
        self.kind = kind
        self.seconds = seconds
        self.agitationEverySec = agitationEverySec
    }
}

/// One row in the temperature what-if table.
struct TempTimePoint: Identifiable, Equatable {
    var id: Double { tempC }
    let tempC: Double
    let devSec: Int
}

/// Pure, well-commented development math. No I/O, no state — fully testable.
enum DevEngine {

    /// Lower bound so a wildly hot dev temperature never yields an unusable time.
    static let minDevSec = 30

    // MARK: - Temperature compensation

    /// Factor applied to the base dev time for a given chemistry temperature.
    ///
    /// Uses an exponential model: `exp(−0.081 · (tempC − baseTempC))`, which is the
    /// classic ≈ −8 %/°C when warmer (shorter time) and ≈ +8 %/°C when cooler
    /// (longer time). At `tempC == baseTempC` the factor is exactly 1.
    static func tempFactor(tempC: Double, baseTempC: Double) -> Double {
        exp(-0.081 * (tempC - baseTempC))
    }

    // MARK: - Push / pull compensation

    /// Multipliers anchored at published push/pull guidance. Integer stops in
    /// −2…+3 are returned directly; values in between (none, since stops are
    /// integers, but kept general) are linearly interpolated between anchors.
    /// Out-of-range inputs are clamped to the −2…+3 envelope.
    static func pushFactor(stops: Int) -> Double {
        // Anchor table: stop -> multiplier on dev time.
        let anchors: [(Int, Double)] = [
            (-2, 0.72),
            (-1, 0.85),
            ( 0, 1.00),
            ( 1, 1.25),
            ( 2, 1.50),
            ( 3, 2.00)
        ]
        let lo = anchors.first?.0 ?? -2
        let hi = anchors.last?.0 ?? 3
        let clamped = min(max(stops, lo), hi)

        // Exact anchor hit.
        if let exact = anchors.first(where: { $0.0 == clamped }) {
            return exact.1
        }
        // Linear interpolation between the two bracketing anchors (defensive;
        // integer stops always hit an anchor above).
        for i in 0..<(anchors.count - 1) {
            let (a, fa) = anchors[i]
            let (b, fb) = anchors[i + 1]
            if clamped > a && clamped < b {
                let t = Double(clamped - a) / Double(b - a)
                return fa + (fb - fa) * t
            }
        }
        return 1.0
    }

    // MARK: - Adjusted develop time

    /// The compensated develop time in seconds for a base time, temperature and
    /// push/pull. Always clamped to at least `minDevSec`.
    static func adjustedDevSec(baseTimeSec: Int,
                               baseTempC: Double,
                               tempC: Double,
                               pushPull: Int) -> Int {
        let safeBase = max(baseTimeSec, 1)
        let factor = pushFactor(stops: pushPull) * tempFactor(tempC: tempC, baseTempC: baseTempC)
        let raw = Double(safeBase) * factor
        let rounded = Int(raw.rounded())
        return max(rounded, minDevSec)
    }

    // MARK: - Full phase plan

    /// Build the ordered four-phase plan for a recipe at a given temperature and
    /// push/pull. Only the develop time is temperature/push compensated; stop,
    /// fix and wash carry from the recipe (temperature matters far less there).
    static func phases(baseTimeSec: Int,
                       baseTempC: Double,
                       stopSec: Int,
                       fixSec: Int,
                       washSec: Int,
                       tempC: Double,
                       pushPull: Int,
                       agitationEverySec: Int) -> [Phase] {
        let dev = adjustedDevSec(baseTimeSec: baseTimeSec,
                                 baseTempC: baseTempC,
                                 tempC: tempC,
                                 pushPull: pushPull)
        return [
            Phase(kind: .develop, seconds: dev, agitationEverySec: max(0, agitationEverySec)),
            Phase(kind: .stop,    seconds: max(0, stopSec), agitationEverySec: 0),
            Phase(kind: .fix,     seconds: max(0, fixSec),  agitationEverySec: max(0, agitationEverySec)),
            Phase(kind: .wash,    seconds: max(0, washSec), agitationEverySec: 0)
        ].filter { $0.seconds > 0 }
    }

    // MARK: - What-if table

    /// Develop time across a temperature range (inclusive), at a fixed push/pull.
    /// Useful for the reference chart and recipe detail mini-table.
    static func tempTable(baseTimeSec: Int,
                          baseTempC: Double,
                          pushPull: Int = 0,
                          from lo: Double = 18,
                          to hi: Double = 26,
                          step: Double = 1.0) -> [TempTimePoint] {
        guard step > 0, hi >= lo else { return [] }
        var points: [TempTimePoint] = []
        var t = lo
        // Guard against runaway loops with a hard cap.
        var guardCount = 0
        while t <= hi + 0.0001 && guardCount < 1000 {
            let sec = adjustedDevSec(baseTimeSec: baseTimeSec,
                                     baseTempC: baseTempC,
                                     tempC: t,
                                     pushPull: pushPull)
            points.append(TempTimePoint(tempC: (t * 10).rounded() / 10, devSec: sec))
            t += step
            guardCount += 1
        }
        return points
    }

    // MARK: - Formatting helpers

    /// "mm:ss" for a non-negative seconds count.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// "m:ss" total of an array of phases.
    static func totalClock(_ phases: [Phase]) -> String {
        clock(phases.reduce(0) { $0 + $1.seconds })
    }
}
