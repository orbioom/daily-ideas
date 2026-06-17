import Foundation

/// A computed step on the cook timeline.
struct PhaseStep: Identifiable {
    let id = UUID()
    let phase: CookPhase
    let isCurrent: Bool
    let isComplete: Bool
}

/// Pure cook math: time estimates, phase timeline, stall detection.
/// Every division and array access is guarded — no traps on user input.
enum CookEngine {

    /// Estimated total cook minutes = weight(lb) × minutes/lb for the cut/method.
    /// Falls back to a sane per-method default when no guide entry is known.
    static func estimatedTotalMinutes(weightKg: Double, method: CookMethod, guide: GuideEntry?) -> Double {
        let lb = max(Units.kgToLb(weightKg), 0)
        let perLb: Double
        if let guide, guide.minutesPerLb > 0 {
            perLb = guide.minutesPerLb
        } else {
            switch method {
            case .grill: perLb = 10
            case .smoke: perLb = 75
            case .roast: perLb = 25
            case .reverseSear: perLb = 30
            }
        }
        // A short cut still takes some minimum time (preheat + handling).
        return max(lb * perLb, 5)
    }

    /// Elapsed seconds since the cook started, clamped to >= 0.
    static func elapsedSeconds(start: Date?, now: Date) -> TimeInterval {
        guard let start else { return 0 }
        return max(now.timeIntervalSince(start), 0)
    }

    /// Estimated "done by" wall-clock time from the start date and total estimate.
    static func doneByDate(start: Date?, totalMinutes: Double) -> Date? {
        guard let start else { return nil }
        return start.addingTimeInterval(totalMinutes * 60)
    }

    /// "Rest until" time once resting begins.
    static func restUntilDate(restStart: Date?, restMinutes: Int) -> Date? {
        guard let restStart else { return nil }
        return restStart.addingTimeInterval(Double(max(restMinutes, 0)) * 60)
    }

    /// Fraction of the estimated cook completed by time, clamped 0...1.
    static func timeProgress(elapsed: TimeInterval, totalMinutes: Double) -> Double {
        guard totalMinutes > 0 else { return 0 }
        return min(max(elapsed / (totalMinutes * 60), 0), 1)
    }

    /// Fraction of the way to target internal temp by temperature, clamped 0...1.
    /// Uses a nominal raw start of 4°C so progress is meaningful from the first reading.
    static func tempProgress(currentC: Double?, targetC: Double) -> Double {
        guard let currentC, targetC > 4 else { return 0 }
        let span = targetC - 4
        guard span > 0 else { return 0 }
        return min(max((currentC - 4) / span, 0), 1)
    }

    /// Stall detection: only meaningful while smoking. True when the internal temp
    /// sits in the ~68–74°C band (150–165°F) and is climbing slowly.
    /// `recentRiseCPerMin` is the recent rate of change in °C per minute.
    static func isStalling(method: CookMethod,
                           status: CookStatus,
                           currentC: Double?,
                           recentRiseCPerMin: Double?) -> Bool {
        guard method.watchesStall, status == .cooking, let c = currentC else { return false }
        let inBand = c >= 68 && c <= 74
        let slow = (recentRiseCPerMin ?? 0) < 0.15   // less than ~0.15°C/min
        return inBand && slow
    }

    /// Recent rise rate in °C per minute from the last two-ish readings.
    static func recentRiseCPerMin(logs: [TempLog]) -> Double? {
        let sorted = logs.sorted { $0.time < $1.time }
        guard sorted.count >= 2,
              let last = sorted.last,
              let prev = sorted[safe: sorted.count - 2] else { return nil }
        let minutes = last.time.timeIntervalSince(prev.time) / 60
        guard minutes > 0 else { return nil }
        return (last.internalTempC - prev.internalTempC) / minutes
    }

    /// The current phase, derived from status, temperature progress and stall.
    static func currentPhase(method: CookMethod,
                             status: CookStatus,
                             elapsed: TimeInterval,
                             totalMinutes: Double,
                             currentC: Double?,
                             targetC: Double,
                             stalling: Bool) -> CookPhase {
        switch status {
        case .planned:
            return .preheat
        case .resting:
            return .rest
        case .done:
            return .rest
        case .cooking:
            let tp = tempProgress(currentC: currentC, targetC: targetC)
            if let c = currentC, c >= targetC { return .pull }
            if stalling { return .stall }
            // Early minutes read as preheat until heat is established.
            if elapsed < 8 * 60 && tp < 0.05 { return .preheat }
            if method.watchesStall && tp > 0.55 && tp < 0.9 { return .wrap }
            return .cook
        }
    }

    /// The ordered timeline for display, marking current and completed phases.
    /// Skips wrap/stall for methods that don't smoke.
    static func timeline(method: CookMethod, current: CookPhase) -> [PhaseStep] {
        var phases: [CookPhase] = [.preheat, .cook]
        if method.watchesStall {
            phases.append(.stall)
            phases.append(.wrap)
        }
        phases.append(.pull)
        phases.append(.rest)

        let currentIndex = phases.firstIndex(of: current)
        return phases.enumerated().map { idx, phase in
            let isCurrent = (phase == current)
            let isComplete: Bool
            if let ci = currentIndex {
                isComplete = idx < ci
            } else {
                isComplete = false
            }
            return PhaseStep(phase: phase, isCurrent: isCurrent, isComplete: isComplete)
        }
    }
}
