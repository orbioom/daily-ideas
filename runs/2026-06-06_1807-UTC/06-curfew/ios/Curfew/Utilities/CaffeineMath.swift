import Foundation

/// First-order pharmacokinetics for caffeine. The amount remaining from a dose
/// decays by half every `halfLife` hours: remaining = dose · (½)^(elapsed/halfLife).
/// Pure value type; all functions guard against bad input.
enum CaffeineMath {

    /// A single dose: when it was taken and how many mg.
    struct Dose { let time: Date; let mg: Double }

    /// Total caffeine (mg) still in the body at `instant`, summing all doses.
    /// Doses in the future contribute nothing.
    static func level(at instant: Date, doses: [Dose], halfLifeHours: Double) -> Double {
        guard halfLifeHours > 0 else { return 0 }
        var total = 0.0
        for d in doses where d.time <= instant {
            let elapsedH = instant.timeIntervalSince(d.time) / 3600.0
            total += d.mg * pow(0.5, elapsedH / halfLifeHours)
        }
        return max(0, total)
    }

    /// Sample the level curve from `start` to `end` at `stepMinutes` resolution.
    static func curve(from start: Date, to end: Date, doses: [Dose],
                      halfLifeHours: Double, stepMinutes: Int = 15) -> [(time: Date, mg: Double)] {
        guard end > start, stepMinutes > 0 else { return [] }
        let step = Double(stepMinutes) * 60.0
        var points: [(Date, Double)] = []
        var t = start
        while t <= end {
            points.append((t, level(at: t, doses: doses, halfLifeHours: halfLifeHours)))
            t = t.addingTimeInterval(step)
        }
        return points.map { (time: $0.0, mg: $0.1) }
    }

    /// The first time at or after `from` when the level drops to/below `threshold`.
    /// Returns nil if it's already below, or never reaches it within `maxHours`.
    static func timeToFallBelow(_ threshold: Double, from: Date, doses: [Dose],
                                halfLifeHours: Double, maxHours: Double = 36) -> Date? {
        guard halfLifeHours > 0, threshold > 0 else { return nil }
        if level(at: from, doses: doses, halfLifeHours: halfLifeHours) <= threshold { return nil }
        let stepMin = 5.0
        var t = from
        let limit = from.addingTimeInterval(maxHours * 3600)
        while t <= limit {
            if level(at: t, doses: doses, halfLifeHours: halfLifeHours) <= threshold { return t }
            t = t.addingTimeInterval(stepMin * 60)
        }
        return nil
    }

    /// The latest time you could take a `newDoseMg` drink so that your level at
    /// `bedtime` stays at or below `targetAtBed`, given existing `doses`.
    ///
    /// Returns:
    ///   .anytime   — even drinking now keeps you under target
    ///   .by(date)  — the last safe moment
    ///   .alreadyOver — existing intake alone already exceeds the target
    enum SafeTime { case anytime, by(Date), alreadyOver }

    static func lastSafeTime(bedtime: Date, targetAtBed: Double, newDoseMg: Double,
                             doses: [Dose], halfLifeHours: Double) -> SafeTime {
        guard halfLifeHours > 0, newDoseMg > 0 else { return .anytime }
        let existingAtBed = level(at: bedtime, doses: doses, halfLifeHours: halfLifeHours)
        let headroom = targetAtBed - existingAtBed
        if headroom <= 0 { return .alreadyOver }
        let ratio = headroom / newDoseMg          // required (½)^((bed-t)/hl) ≤ ratio
        if ratio >= 1 { return .anytime }
        // (bed - t)/hl ≥ log_0.5(ratio) = ln(ratio)/ln(0.5)
        let halfLivesNeeded = log(ratio) / log(0.5)
        let secondsBefore = halfLivesNeeded * halfLifeHours * 3600.0
        return .by(bedtime.addingTimeInterval(-secondsBefore))
    }

    /// Level at `bedtime` if a `newDoseMg` drink is taken at `at`.
    static func projectedAtBed(bedtime: Date, newDoseMg: Double, at: Date,
                               doses: [Dose], halfLifeHours: Double) -> Double {
        let base = level(at: bedtime, doses: doses, halfLifeHours: halfLifeHours)
        let extra = bedtime >= at && halfLifeHours > 0
            ? newDoseMg * pow(0.5, bedtime.timeIntervalSince(at) / 3600.0 / halfLifeHours)
            : 0
        return max(0, base + extra)
    }
}
